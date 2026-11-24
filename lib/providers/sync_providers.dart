import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../services/backup_service.dart';
import '../services/cloud_backup_client.dart';
import '../services/person_photo_store.dart';
import '../services/sync_service.dart';
import 'backup_providers.dart';
import 'database_provider.dart';
import 'shared_preferences_provider.dart';

final _log = Logger('Sync');

/// Names this installation in the sync folder. Not in backups: two devices
/// restored from the same backup must not share it.
const syncDeviceIdKey = 'sync_device_id';

final syncServiceProvider = Provider<SyncService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  var device = prefs.getString(syncDeviceIdKey);
  if (device == null) {
    device = const Uuid().v4();
    unawaited(prefs.setString(syncDeviceIdKey, device));
  }
  return SyncService(
    ref.watch(databaseProvider),
    deviceId: device,
    photos: ref.watch(personPhotoStoreProvider),
    aircraftPhotos: ref.watch(aircraftPhotoStoreProvider),
    signatures: ref.watch(signatureStoreProvider),
  );
});

/// How syncing through one cloud destination went.
class SyncStatus {
  const SyncStatus({this.lastSyncAt, this.lastError, this.running = false});

  final DateTime? lastSyncAt;
  final String? lastError;
  final bool running;
}

final syncControllerProvider =
    NotifierProvider<SyncController, Map<BackupDestination, SyncStatus>>(
      SyncController.new,
    );

/// Runs the syncs the user turned on in the backup settings.
class SyncController extends Notifier<Map<BackupDestination, SyncStatus>> {
  static String _key(BackupDestination d, String field) =>
      'sync_${d.name}_$field';

  /// Pending sync after a change, see [syncOnChanges].
  Timer? _debounce;
  StreamSubscription<void>? _changes;

  /// [SyncService.localChanges] when [syncAll] last started.
  int? _synced;

  @override
  Map<BackupDestination, SyncStatus> build() {
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(_changes?.cancel());
    });
    final prefs = ref.read(sharedPreferencesProvider);
    return {
      for (final d in BackupDestination.cloud)
        d: SyncStatus(
          lastSyncAt: DateTime.tryParse(
            prefs.getString(_key(d, 'last_at')) ?? '',
          ),
          lastError: prefs.getString(_key(d, 'last_error')),
        ),
    };
  }

  SyncStatus statusOf(BackupDestination d) => state[d] ?? const SyncStatus();

  /// Syncs every destination that has sync on and is connected. Safe to
  /// call often (app start, resume, pause); never throws.
  Future<void> syncAll() async {
    _synced = await ref.read(syncServiceProvider).localChanges();
    final settings = await ref.read(backupSettingsProvider.future);
    final on = [
      for (final d in BackupDestination.cloud)
        if (settings.of(d).sync && await ref.read(cloudAuthProvider(d).future))
          d,
    ];
    Future<int> tryNow(BackupDestination d) async {
      try {
        return await syncNow(d);
      } catch (e) {
        // Already in the destination's status.
        _log.warning('${d.name} sync failed: $e');
        return 0;
      }
    }

    // Syncing through two clouds relays between them: what one brought goes
    // to those synced before it too.
    var relay = 0;
    for (final (i, d) in on.indexed) {
      if (await tryNow(d) > 0) relay = i;
    }
    for (final d in on.take(relay)) {
      await tryNow(d);
    }
  }

  /// Syncs a moment after this device changes something that is synced, so
  /// an edit doesn't wait for the app to be left.
  void syncOnChanges() {
    _changes ??= ref.read(databaseProvider).tableUpdates().listen((_) {
      _debounce?.cancel();
      _debounce = Timer(_quiet, _syncIfChanged);
    });
  }

  // Lets the statements of one save, or a burst of edits, go out together.
  static const _quiet = Duration(seconds: 2);

  Future<void> _syncIfChanged() async {
    if (state.values.any((s) => s.running)) {
      // Its own writes, or edits made meanwhile: look again when it's done.
      _debounce = Timer(_quiet, _syncIfChanged);
      return;
    }
    if (await ref.read(syncServiceProvider).localChanges() == _synced) return;
    await syncAll();
  }

  /// Syncs through [d] now, unless a sync is running; returns how many
  /// changes it received. Throws a [BackupException] on failure (also kept in
  /// the status).
  Future<int> syncNow(BackupDestination d) async {
    var received = 0;
    await _locked(() async => received = await _sync(d));
    return received;
  }

  Future<int> _sync(BackupDestination d) async {
    final prefs = ref.read(sharedPreferencesProvider);
    // The other isolate may have synced since this one read them.
    await prefs.reload();
    _set(d, SyncStatus(lastSyncAt: statusOf(d).lastSyncAt, running: true));
    try {
      final outcome = await ref
          .read(syncServiceProvider)
          .sync(
            ref.read(cloudSyncClientProvider(d)),
            applied: (prefs.getStringList(_key(d, 'applied')) ?? []).toSet(),
            pushed: prefs.getString(_key(d, 'pushed')),
          );
      final now = DateTime.now();
      await prefs.setStringList(_key(d, 'applied'), [...outcome.applied]);
      await prefs.setString(_key(d, 'pushed'), outcome.pushed);
      await prefs.setString(_key(d, 'last_at'), now.toIso8601String());
      await prefs.remove(_key(d, 'last_error'));
      _set(d, SyncStatus(lastSyncAt: now));
      if (outcome.received > 0) {
        _log.info('${d.name}: ${outcome.received} change(s) received.');
      }
      return outcome.received;
    } catch (e) {
      final message = BackupController.errorMessage(e);
      await prefs.setString(_key(d, 'last_error'), message);
      _set(
        d,
        SyncStatus(lastSyncAt: statusOf(d).lastSyncAt, lastError: message),
      );
      if (e is CloudReauthRequired) {
        await ref.read(cloudAuthProvider(d).notifier).sessionExpired(e.message);
      }
      throw e is BackupException ? e : BackupException(message);
    }
  }

  /// Stops syncing through [d] and empties its sync folder. Other devices
  /// still syncing there upload their own data again. Throws a
  /// [BackupException] if it can't.
  Future<void> deleteSyncData(BackupDestination d) async {
    await ref.read(backupSettingsProvider.notifier).setSync(d, false);
    final done = await _locked(() async {
      final client = ref.read(cloudSyncClientProvider(d));
      for (final f in await client.list()) {
        await client.delete(f.id);
      }
    });
    if (!done) {
      throw const BackupException('A sync is running: try again in a moment.');
    }
    await reset(d);
  }

  /// Runs [body] holding the sync lock; false, without running it, if a sync
  /// holds it. One lock for every destination: a [SyncService] runs one sync
  /// at a time. The app and the background sync (main.dart) run in separate
  /// isolates: the name server is shared by the whole process.
  static Future<bool> _locked(Future<void> Function() body) async {
    const name = 'sync';
    final mine = Isolate.current.controlPort;
    if (!IsolateNameServer.registerPortWithName(mine, name)) {
      final holder = IsolateNameServer.lookupPortByName(name);
      if (holder != null && await _alive(Isolate(holder))) return false;
      // Its isolate was killed (WorkManager stopping the background sync)
      // before it could release it.
      if (IsolateNameServer.lookupPortByName(name) == holder) {
        IsolateNameServer.removePortNameMapping(name);
      }
      if (!IsolateNameServer.registerPortWithName(mine, name)) return false;
    }
    try {
      await body();
      return true;
    } finally {
      IsolateNameServer.removePortNameMapping(name);
    }
  }

  /// Whether [isolate] answers; it does even while busy.
  static Future<bool> _alive(Isolate isolate) async {
    final pong = ReceivePort();
    isolate.ping(pong.sendPort, response: true);
    final alive = await pong.first.timeout(
      const Duration(seconds: 1),
      onTimeout: () => false,
    );
    pong.close();
    return alive as bool;
  }

  /// Forgets what was synced through [d]: another account may come next.
  Future<void> reset(BackupDestination d) async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final field in ['last_at', 'last_error', 'applied', 'pushed']) {
      await prefs.remove(_key(d, field));
    }
    _set(d, const SyncStatus());
  }

  void _set(BackupDestination d, SyncStatus status) =>
      state = {...state, d: status};
}
