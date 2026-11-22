import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backup_service.dart';
import '../services/cloud_backup_client.dart';
import '../services/dropbox_client.dart';
import '../services/google_drive_client.dart';
import '../services/local_backup_store.dart';
import '../services/oauth_callback_service.dart';
import '../services/oauth_service.dart';
import '../services/person_photo_store.dart';
import 'app_settings_backup.dart';
import 'database_provider.dart';

final _log = Logger('Backup');

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------

enum BackupFrequency {
  manual('Off', null),
  daily('Daily', Duration(hours: 20)),
  weekly('Weekly', Duration(days: 6, hours: 20));

  const BackupFrequency(this.label, this.dueAfter);
  final String label;

  /// Minimum time since the last backup before an automatic one runs. A bit
  /// shorter than the nominal period so a "daily" backup still happens when
  /// the app is opened slightly earlier than yesterday.
  final Duration? dueAfter;
}

enum BackupDestination {
  dropbox('Dropbox'),
  googleDrive('Google Drive'),
  local('This device');

  const BackupDestination(this.label);
  final String label;

  bool get isCloud => this != local;

  static const cloud = [dropbox, googleDrive];
}

/// How one destination is backed up to.
class DestinationSettings {
  const DestinationSettings({
    required this.includePhotos,
    required this.frequency,
    required this.keep,
  });

  final bool includePhotos;
  final BackupFrequency frequency;

  /// Backups kept; older ones are deleted after each backup.
  final int keep;

  static const keepChoices = [3, 5];
  static const keepMin = 1;
  static const keepMax = 100;

  static DestinationSettings defaultsFor(BackupDestination d) =>
      DestinationSettings(
        includePhotos: true,
        frequency: BackupFrequency.weekly,
        keep: d.isCloud ? 3 : 5,
      );

  DestinationSettings copyWith({
    bool? includePhotos,
    BackupFrequency? frequency,
    int? keep,
  }) => DestinationSettings(
    includePhotos: includePhotos ?? this.includePhotos,
    frequency: frequency ?? this.frequency,
    keep: keep ?? this.keep,
  );
}

class BackupSettings {
  const BackupSettings(this._byDestination);

  final Map<BackupDestination, DestinationSettings> _byDestination;

  DestinationSettings of(BackupDestination d) =>
      _byDestination[d] ?? DestinationSettings.defaultsFor(d);

  BackupSettings withDestination(BackupDestination d, DestinationSettings s) =>
      BackupSettings({..._byDestination, d: s});
}

class BackupSettingsNotifier extends AsyncNotifier<BackupSettings> {
  static String photosKey(BackupDestination d) =>
      'backup_${d.name}_include_photos';
  static String frequencyKey(BackupDestination d) =>
      'backup_${d.name}_frequency';
  static String keepKey(BackupDestination d) => 'backup_${d.name}_keep';

  @override
  Future<BackupSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupSettings({
      for (final d in BackupDestination.values) d: _read(prefs, d),
    });
  }

  static DestinationSettings _read(
    SharedPreferences prefs,
    BackupDestination d,
  ) {
    final defaults = DestinationSettings.defaultsFor(d);
    return DestinationSettings(
      includePhotos: prefs.getBool(photosKey(d)) ?? defaults.includePhotos,
      frequency: BackupFrequency.values.firstWhere(
        (f) => f.name == prefs.getString(frequencyKey(d)),
        orElse: () => defaults.frequency,
      ),
      keep: prefs.getInt(keepKey(d)) ?? defaults.keep,
    );
  }

  Future<void> _update(
    BackupDestination d,
    DestinationSettings Function(DestinationSettings) change,
  ) async {
    final current = await future;
    state = AsyncData(current.withDestination(d, change(current.of(d))));
  }

  Future<void> setIncludePhotos(BackupDestination d, bool value) async {
    await _update(d, (s) => s.copyWith(includePhotos: value));
    await (await SharedPreferences.getInstance()).setBool(photosKey(d), value);
  }

  Future<void> setFrequency(BackupDestination d, BackupFrequency value) async {
    await _update(d, (s) => s.copyWith(frequency: value));
    await (await SharedPreferences.getInstance()).setString(
      frequencyKey(d),
      value.name,
    );
    unawaited(ref.read(backupControllerProvider.notifier).runAutomatic());
  }

  /// Takes effect at the next backup, which prunes down to [value].
  Future<void> setKeep(BackupDestination d, int value) async {
    await _update(d, (s) => s.copyWith(keep: value));
    await (await SharedPreferences.getInstance()).setInt(keepKey(d), value);
  }
}

final backupSettingsProvider =
    AsyncNotifierProvider<BackupSettingsNotifier, BackupSettings>(
      BackupSettingsNotifier.new,
    );

// -----------------------------------------------------------------------------
// Services
// -----------------------------------------------------------------------------

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    ref.watch(personPhotoStoreProvider),
    ref.watch(aircraftPhotoStoreProvider),
    ref.watch(signatureStoreProvider),
    getTemporaryDirectory,
  );
});

final localBackupStoreProvider = Provider<LocalBackupStore>((ref) {
  return LocalBackupStore(getApplicationSupportDirectory);
});

/// Google allows Android OAuth clients a custom-scheme redirect on the
/// package name (with "Custom URI scheme" enabled in the client's advanced
/// settings), and iOS clients one on the bundle ID. Registered in
/// AndroidManifest.xml and Info.plist; iOS builds need an iOS client's ID.
const googleRedirectUri = 'it.winstriker.zenith:/oauth2redirect';

/// The dart-define holding each cloud provider's OAuth client ID.
const _clientIdDefine = {
  BackupDestination.dropbox: 'DROPBOX_APP_KEY',
  BackupDestination.googleDrive: 'GOOGLE_CLIENT_ID',
};

final cloudOAuthProvider = Provider.family<OAuthService, BackupDestination>((
  ref,
  destination,
) {
  switch (destination) {
    case BackupDestination.dropbox:
      return OAuthService(
        "dropbox",
        "https://www.dropbox.com/oauth2/authorize",
        "https://api.dropboxapi.com/oauth2/token",
        const String.fromEnvironment("DROPBOX_APP_KEY"),
        "zenithlogbook://dropbox",
        // Must match the scopes enabled in the Dropbox App Console.
        "account_info.read files.metadata.read files.content.write "
            "files.content.read",
        authorizationParams: const {'token_access_type': 'offline'},
      );
    case BackupDestination.googleDrive:
      const clientId = String.fromEnvironment("GOOGLE_CLIENT_ID");
      return OAuthService(
        "google_drive",
        "https://accounts.google.com/o/oauth2/v2/auth",
        "https://oauth2.googleapis.com/token",
        clientId,
        googleRedirectUri,
        // Only the files Zenith creates: no app verification needed.
        "https://www.googleapis.com/auth/drive.file",
        // A refresh token is only issued for offline access, and only on
        // the consent screen.
        authorizationParams: const {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
    case BackupDestination.local:
      throw ArgumentError.value(destination, 'destination', 'not a cloud');
  }
});

final cloudClientProvider =
    Provider.family<CloudBackupClient, BackupDestination>((ref, destination) {
      final auth = ref.watch(cloudOAuthProvider(destination));
      return switch (destination) {
        BackupDestination.dropbox => DropboxClient(auth),
        BackupDestination.googleDrive => GoogleDriveClient(auth),
        BackupDestination.local => throw ArgumentError.value(
          destination,
          'destination',
          'not a cloud',
        ),
      };
    });

// -----------------------------------------------------------------------------
// Cloud sessions
// -----------------------------------------------------------------------------

/// One-off messages for the user (login failures, expired sessions).
/// The backup page shows them as snack bars and then clears them.
class BackupNoticeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void show(String message) => state = message;
  void clear() => state = null;
}

final backupNoticeProvider = NotifierProvider<BackupNoticeNotifier, String?>(
  BackupNoticeNotifier.new,
);

/// Whether each cloud destination is connected.
final cloudAuthProvider =
    AsyncNotifierProvider.family<CloudAuthNotifier, bool, BackupDestination>(
      CloudAuthNotifier.new,
    );

class CloudAuthNotifier extends AsyncNotifier<bool> {
  CloudAuthNotifier(this.destination);
  final BackupDestination destination;

  OAuthService get _service => ref.read(cloudOAuthProvider(destination));

  @override
  Future<bool> build() => _service.isLoggedIn();

  Future<void> login() async {
    if (_service.clientId.isEmpty) {
      throw BackupException(
        '${destination.label} is not configured in this build '
        '(missing ${_clientIdDefine[destination]}).',
      );
    }
    final url = await _service.startLogin();
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const BackupException('Could not open the browser to sign in.');
    }
  }

  Future<void> logout() async {
    await ref.read(cloudClientProvider(destination)).revoke();
    await _signedOut();
  }

  /// Called when the provider rejects our tokens.
  Future<void> sessionExpired(String message) async {
    await _signedOut();
    ref.read(backupNoticeProvider.notifier).show(message);
  }

  Future<void> _signedOut() async {
    await _service.logout();
    state = const AsyncData(false);
    // A different account may be connected next: forget what was uploaded.
    await ref.read(backupControllerProvider.notifier).resetStatus(destination);
  }
}

final cloudAccountProvider = FutureProvider.autoDispose
    .family<CloudAccount?, BackupDestination>((ref, destination) async {
      if (!await ref.watch(cloudAuthProvider(destination).future)) return null;
      try {
        return await ref
            .read(cloudClientProvider(destination))
            .currentAccount();
      } on CloudReauthRequired catch (e) {
        unawaited(
          ref
              .read(cloudAuthProvider(destination).notifier)
              .sessionExpired(e.message),
        );
        return null;
      }
    });

final cloudBackupsProvider = FutureProvider.autoDispose
    .family<List<RemoteBackup>, BackupDestination>((ref, destination) async {
      if (!await ref.watch(cloudAuthProvider(destination).future)) return [];
      try {
        return await ref.read(cloudClientProvider(destination)).list();
      } on CloudReauthRequired catch (e) {
        unawaited(
          ref
              .read(cloudAuthProvider(destination).notifier)
              .sessionExpired(e.message),
        );
        return [];
      }
    });

final localBackupsProvider = FutureProvider.autoDispose<List<LocalBackup>>((
  ref,
) {
  return ref.watch(localBackupStoreProvider).list();
});

final callbackServiceProvider = Provider((ref) {
  final services = {
    for (final d in BackupDestination.cloud)
      d: ref.watch(cloudOAuthProvider(d)),
  };
  BackupDestination destinationOf(OAuthService service) =>
      services.entries.firstWhere((e) => e.value == service).key;

  final handler = OAuthCallbackHandler(
    oauthServices: services.values.toList(),
    onLoginSuccess: (service) {
      final destination = destinationOf(service);
      ref.invalidate(cloudAuthProvider(destination));
      ref
          .read(backupNoticeProvider.notifier)
          .show('${destination.label} connected');
      // First backup right away, if automatic backups are on.
      unawaited(ref.read(backupControllerProvider.notifier).runAutomatic());
    },
    onLoginError: (service, error) {
      ref
          .read(backupNoticeProvider.notifier)
          .show(
            '${destinationOf(service).label} login failed: '
            '${error is OAuthException ? error.message : error}',
          );
    },
  );
  ref.onDispose(handler.dispose);
  return handler;
});

// -----------------------------------------------------------------------------
// Backup runs
// -----------------------------------------------------------------------------

class DestinationStatus {
  const DestinationStatus({this.lastBackupAt, this.lastError, this.lastHash});
  final DateTime? lastBackupAt;
  final String? lastError;

  /// Content hash of the last backup, to skip unchanged automatic backups.
  final String? lastHash;
}

class BackupState {
  const BackupState({
    this.statuses = const {},
    this.running = const {},
    this.restoring = false,
  });

  final Map<BackupDestination, DestinationStatus> statuses;
  final Set<BackupDestination> running;
  final bool restoring;

  DestinationStatus statusOf(BackupDestination d) =>
      statuses[d] ?? const DestinationStatus();

  bool get busy => running.isNotEmpty || restoring;

  BackupState copyWith({
    Map<BackupDestination, DestinationStatus>? statuses,
    Set<BackupDestination>? running,
    bool? restoring,
  }) => BackupState(
    statuses: statuses ?? this.statuses,
    running: running ?? this.running,
    restoring: restoring ?? this.restoring,
  );
}

final backupControllerProvider =
    AsyncNotifierProvider<BackupController, BackupState>(BackupController.new);

class BackupController extends AsyncNotifier<BackupState> {
  bool _autoRunning = false;

  static String _key(BackupDestination d, String field) =>
      'backup_${d.name}_$field';

  @override
  Future<BackupState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupState(
      statuses: {
        for (final d in BackupDestination.values)
          d: DestinationStatus(
            lastBackupAt: DateTime.tryParse(
              prefs.getString(_key(d, 'last_at')) ?? '',
            ),
            lastError: prefs.getString(_key(d, 'last_error')),
            lastHash: prefs.getString(_key(d, 'last_hash')),
          ),
      },
    );
  }

  /// Backs up to [destination] now, regardless of schedule. Throws a
  /// [BackupException] on failure (also recorded in the status).
  Future<void> backUp(BackupDestination destination) async {
    final settings = await ref.read(backupSettingsProvider.future);
    await _runFor([destination], settings, automatic: false);
  }

  /// Runs every automatic backup that is due. Safe to call often: on app
  /// start, on resume and after settings change. Never throws.
  Future<void> runAutomatic() async {
    if (_autoRunning) return;
    _autoRunning = true;
    try {
      final settings = await ref.read(backupSettingsProvider.future);
      final current = await future;
      if (current.busy) return;

      final due = <BackupDestination>[];
      for (final d in BackupDestination.values) {
        final dueAfter = settings.of(d).frequency.dueAfter;
        if (dueAfter == null) continue;
        if (d.isCloud && !await ref.read(cloudAuthProvider(d).future)) {
          continue;
        }
        final last = current.statusOf(d).lastBackupAt;
        if (last == null || DateTime.now().difference(last) >= dueAfter) {
          due.add(d);
        }
      }
      if (due.isEmpty) return;
      _log.info('Automatic backup due for ${due.map((d) => d.name)}');
      await _runFor(due, settings, automatic: true);
    } catch (e) {
      // Already recorded in the destination's status.
      _log.warning('Automatic backup failed: $e');
    } finally {
      _autoRunning = false;
    }
  }

  Future<void> _runFor(
    List<BackupDestination> destinations,
    BackupSettings settings, {
    required bool automatic,
  }) async {
    final current = await future;
    final todo = destinations.where((d) => !current.running.contains(d));
    if (todo.isEmpty || current.restoring) return;
    _setRunning(todo, true);

    Object? firstError;
    try {
      // Destinations that want the same content share one snapshot.
      final groups = <bool, List<BackupDestination>>{};
      for (final d in todo) {
        groups.putIfAbsent(settings.of(d).includePhotos, () => []).add(d);
      }
      for (final MapEntry(key: includePhotos, value: group) in groups.entries) {
        final BackupSnapshot snapshot;
        try {
          snapshot = await ref
              .read(backupServiceProvider)
              .create(
                includePhotos: includePhotos,
                settings: AppSettingsBackup.read(
                  await SharedPreferences.getInstance(),
                ),
              );
        } catch (e) {
          for (final d in group) {
            await _record(d, error: _message(e));
          }
          firstError ??= e;
          continue;
        }

        // An empty logbook (fresh install) must never push out real backups.
        if (automatic && snapshot.isEmpty) {
          _log.info('Logbook is empty, skipping automatic backup.');
          return;
        }

        for (final d in group) {
          try {
            final unchanged =
                automatic &&
                (await future).statusOf(d).lastHash == snapshot.contentHash;
            if (unchanged) {
              _log.info('${d.name}: no changes since last backup.');
            } else {
              await _upload(d, snapshot, keep: settings.of(d).keep);
            }
            await _record(
              d,
              at: snapshot.createdAt,
              hash: snapshot.contentHash,
            );
          } catch (e) {
            _log.warning('${d.name} backup failed: $e');
            await _record(d, error: _message(e));
            if (e is CloudReauthRequired) {
              await ref
                  .read(cloudAuthProvider(d).notifier)
                  .sessionExpired(e.message);
            }
            firstError ??= e;
          }
        }
      }
    } finally {
      _setRunning(todo, false);
    }
    if (firstError != null) {
      throw firstError is BackupException
          ? firstError
          : BackupException(_message(firstError));
    }
  }

  Future<void> _upload(
    BackupDestination d,
    BackupSnapshot snapshot, {
    required int keep,
  }) async {
    switch (d) {
      case BackupDestination.dropbox || BackupDestination.googleDrive:
        final client = ref.read(cloudClientProvider(d));
        _log.info(
          'Uploading ${snapshot.fileName} '
          '(${(snapshot.bytes.length / 1048576).toStringAsFixed(1)} MB) '
          'to ${d.label}.',
        );
        await client.upload(snapshot.fileName, snapshot.bytes);
        await client.prune(keep: keep);
        ref.invalidate(cloudBackupsProvider(d));
      case BackupDestination.local:
        final store = ref.read(localBackupStoreProvider);
        await store.save(snapshot);
        await store.prune(keep: keep);
        ref.invalidate(localBackupsProvider);
    }
  }

  /// Replaces the logbook with [bytes]. A safety copy of the current data is
  /// saved to local backups first, so a restore can always be undone.
  Future<RestoreSummary> restore(Uint8List bytes) async {
    final current = await future;
    if (current.busy) {
      throw const BackupException('A backup is in progress, try again soon.');
    }
    state = AsyncData(current.copyWith(restoring: true));
    try {
      // Validate before touching anything.
      await BackupService.readHeader(bytes);
      final service = ref.read(backupServiceProvider);
      final store = ref.read(localBackupStoreProvider);
      final prefs = await SharedPreferences.getInstance();
      final safety = await service.create(
        includePhotos: true,
        settings: AppSettingsBackup.read(prefs),
      );
      if (!safety.isEmpty) {
        await store.save(safety, preRestore: true);
        final settings = await ref.read(backupSettingsProvider.future);
        await store.prune(keep: settings.of(BackupDestination.local).keep);
      }
      final summary = await service.restore(bytes);
      if (summary.settings case final settings?) {
        await AppSettingsBackup.restore(ref, settings);
      }
      ref.invalidate(localBackupsProvider);
      // The data changed, so the next automatic backup must upload.
      for (final d in BackupDestination.values) {
        final s = (await future).statusOf(d);
        await _record(d, at: s.lastBackupAt, keepError: true);
      }
      return summary;
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(_message(e));
    } finally {
      state = AsyncData((await future).copyWith(restoring: false));
    }
  }

  Future<Uint8List> downloadFromCloud(
    BackupDestination d,
    RemoteBackup backup,
  ) async {
    try {
      return await ref.read(cloudClientProvider(d)).download(backup.id);
    } on CloudReauthRequired catch (e) {
      await ref.read(cloudAuthProvider(d).notifier).sessionExpired(e.message);
      rethrow;
    }
  }

  Future<void> resetStatus(BackupDestination d) async {
    final prefs = await SharedPreferences.getInstance();
    for (final field in ['last_at', 'last_error', 'last_hash']) {
      await prefs.remove(_key(d, field));
    }
    final current = await future;
    state = AsyncData(
      current.copyWith(
        statuses: {...current.statuses, d: const DestinationStatus()},
      ),
    );
  }

  void _setRunning(Iterable<BackupDestination> ds, bool running) {
    final current = state.value ?? const BackupState();
    state = AsyncData(
      current.copyWith(
        running: running
            ? {...current.running, ...ds}
            : current.running.difference(ds.toSet()),
      ),
    );
  }

  /// Stores the outcome of a run. Success clears the error; failure keeps
  /// the last successful time.
  Future<void> _record(
    BackupDestination d, {
    DateTime? at,
    String? hash,
    String? error,
    bool keepError = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = (await future).statusOf(d);
    final next = error != null
        ? DestinationStatus(
            lastBackupAt: previous.lastBackupAt,
            lastHash: previous.lastHash,
            lastError: error,
          )
        : DestinationStatus(
            lastBackupAt: at,
            lastHash: hash,
            lastError: keepError ? previous.lastError : null,
          );

    Future<void> put(String field, String? value) => value == null
        ? prefs.remove(_key(d, field))
        : prefs.setString(_key(d, field), value);
    await put('last_at', next.lastBackupAt?.toIso8601String());
    await put('last_hash', next.lastHash);
    await put('last_error', next.lastError);

    final current = await future;
    state = AsyncData(
      current.copyWith(statuses: {...current.statuses, d: next}),
    );
  }

  static String _message(Object e) => switch (e) {
    BackupException(:final message) => message,
    OAuthException(:final message) => message,
    // Only a failed DNS lookup really means "offline"; other socket errors
    // (reset, broken pipe, timeout...) need their details to be diagnosed.
    _ when e.toString().contains('Failed host lookup') =>
      'No internet connection.',
    _ when e.toString().contains('SocketException') =>
      'Network error: ${_socketDetails(e.toString())}',
    _ => e.toString(),
  };

  /// "ClientException with SocketException: Broken pipe (OS Error: ...)"
  /// -> "Broken pipe (OS Error: ...)".
  static String _socketDetails(String text) {
    final i = text.indexOf('SocketException:');
    final details = i < 0
        ? text
        : text.substring(i + 'SocketException:'.length).trim();
    return details.length > 200 ? '${details.substring(0, 200)}…' : details;
  }
}
