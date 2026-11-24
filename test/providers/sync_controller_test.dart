import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/providers/backup_providers.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/providers/shared_preferences_provider.dart';
import 'package:zenith/providers/sync_providers.dart';
import 'package:zenith/services/backup_service.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';
import 'package:zenith/services/sync_service.dart';

import '../services/sync_service_test.dart' show Device, FakeFolder;

/// A cloud account that is connected.
class _Connected extends CloudAuthNotifier {
  _Connected(super.destination);
  @override
  Future<bool> build() async => true;
}

/// Sends the control port of its isolate and stays alive.
void _holder(SendPort to) {
  ReceivePort();
  to.send(Isolate.current.controlPort);
}

/// Counts the syncs the change watcher starts.
class _CountingController extends SyncController {
  int syncs = 0;

  @override
  Future<void> syncAll() {
    syncs++;
    return super.syncAll();
  }
}

void main() {
  test('a sync running elsewhere makes syncNow skip', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        // Reaching the service means the sync went ahead.
        syncServiceProvider.overrideWith((ref) => throw StateError('synced')),
      ],
    );
    addTearDown(container.dispose);
    final sync = container.read(syncControllerProvider.notifier);
    const d = BackupDestination.dropbox;

    final other = ReceivePort();
    IsolateNameServer.registerPortWithName(other.sendPort, 'sync');
    await sync.syncNow(d);
    IsolateNameServer.removePortNameMapping('sync');
    other.close();

    // Twice: a failed sync must release the lock too.
    await expectLater(sync.syncNow(d), throwsA(isA<BackupException>()));
    await expectLater(sync.syncNow(d), throwsA(isA<BackupException>()));
  });

  test('the lock of a killed isolate is taken over', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        syncServiceProvider.overrideWith((ref) => throw StateError('synced')),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => IsolateNameServer.removePortNameMapping('sync'));
    final sync = container.read(syncControllerProvider.notifier);
    const d = BackupDestination.dropbox;

    final started = ReceivePort();
    final exited = ReceivePort();
    final holder = await Isolate.spawn(
      _holder,
      started.sendPort,
      onExit: exited.sendPort,
    );
    IsolateNameServer.registerPortWithName(
      await started.first as SendPort,
      'sync',
    );
    await sync.syncNow(d); // alive: skipped

    holder.kill(priority: Isolate.immediate);
    await exited.first;
    await expectLater(sync.syncNow(d), throwsA(isA<BackupException>()));
  });

  test('a change made here syncs a moment later; other writes not', () async {
    SharedPreferences.setMockInitialValues({});
    final db = LogbookDatabase(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('zenith_sync');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        databaseProvider.overrideWithValue(db),
        syncServiceProvider.overrideWithValue(
          SyncService(
            db,
            deviceId: 'aaaa',
            photos: PersonPhotoStore(() async => dir),
            aircraftPhotos: AircraftPhotoStore(() async => dir),
            signatures: SignatureStore(() async => dir),
          ),
        ),
        syncControllerProvider.overrideWith(_CountingController.new),
      ],
    );
    addTearDown(container.dispose);
    final sync =
        container.read(syncControllerProvider.notifier) as _CountingController;
    await sync.syncAll(); // at launch
    sync.syncOnChanges();
    const wait = Duration(milliseconds: 2500);

    // Not synced: a flight still being recorded.
    await db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'REC',
            departureTime: DateTime.utc(2026, 6),
            isRecording: true,
          ),
        );
    await Future<void>.delayed(wait);
    expect(sync.syncs, 1);

    await db
        .into(db.people)
        .insert(PeopleCompanion.insert(name: 'Anna', surname: 'Verdi'));
    await Future<void>.delayed(wait);
    expect(sync.syncs, 2);
  });

  test('a device syncing through both clouds relays between them', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({
      for (final d in BackupDestination.cloud)
        BackupSettingsNotifier.syncKey(d): true,
    });
    final root = await Directory.systemTemp.createTemp('zenith_sync');
    final folders = {for (final d in BackupDestination.cloud) d: FakeFolder()};
    // a syncs through both; b only through the first, c the last.
    final a = Device('aaaa', root);
    final b = Device('bbbb', root);
    final c = Device('cccc', root);
    addTearDown(() async {
      for (final d in [a, b, c]) {
        await d.db.close();
      }
      await root.delete(recursive: true);
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        databaseProvider.overrideWithValue(a.db),
        syncServiceProvider.overrideWithValue(a.sync),
        cloudAuthProvider.overrideWith2(_Connected.new),
        cloudSyncClientProvider.overrideWith((ref, d) => folders[d]!),
      ],
    );
    addTearDown(container.dispose);

    await c.db
        .into(c.db.people)
        .insert(PeopleCompanion.insert(name: 'Carla', surname: 'Neri'));
    await c.syncWith(folders[BackupDestination.cloud.last]!);
    await container.read(syncControllerProvider.notifier).syncAll();
    await b.syncWith(folders[BackupDestination.cloud.first]!);

    final people = await b.db.select(b.db.people).get();
    expect(people.map((p) => p.name), ['Carla']);
  });
}
