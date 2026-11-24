import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/cloud_backup_client.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';
import 'package:zenith/services/sync_service.dart';

/// A cloud folder in memory.
class FakeFolder implements CloudBackupClient {
  final files = <String, Uint8List>{};

  /// When each file arrived, by the server's clock.
  final created = <String, DateTime>{};

  /// How far the server's clock is ahead of the devices'.
  Duration ahead = Duration.zero;

  @override
  Future<List<RemoteBackup>> list() async => [
    for (final MapEntry(:key, :value) in files.entries)
      RemoteBackup(
        name: key,
        id: key,
        size: value.length,
        createdAt: created[key]!,
      ),
  ];

  @override
  Future<void> upload(
    String name,
    Uint8List bytes, {
    TransferProgress? onProgress,
  }) async {
    files[name] = bytes;
    created[name] = DateTime.now().add(ahead);
  }

  /// Runs before each download.
  Future<void> Function(String id)? onDownload;

  @override
  Future<Uint8List> download(
    String id, {
    int? size,
    TransferProgress? onProgress,
  }) async {
    await onDownload?.call(id);
    return files[id]!;
  }

  @override
  Future<void> delete(String id) async => files.remove(id);

  @override
  Future<CloudAccount> currentAccount() => throw UnimplementedError();
  @override
  Future<void> prune({required int keep}) => throw UnimplementedError();
  @override
  Future<void> revoke() => throw UnimplementedError();
}

/// One installation: its database, picture folder and sync.
class Device {
  Device(String id, Directory root)
    : db = LogbookDatabase(NativeDatabase.memory()),
      photos = PersonPhotoStore(() async => Directory('${root.path}/$id')) {
    sync = SyncService(
      db,
      deviceId: id,
      photos: photos,
      aircraftPhotos: AircraftPhotoStore(
        () async => Directory('${root.path}/$id'),
      ),
      signatures: SignatureStore(() async => Directory('${root.path}/$id')),
    );
  }

  final LogbookDatabase db;
  final PersonPhotoStore photos;
  late final SyncService sync;
  Set<String> applied = {};
  String? pushed;

  Future<int> syncWith(FakeFolder folder) async {
    final outcome = await sync.sync(folder, applied: applied, pushed: pushed);
    applied = outcome.applied;
    pushed = outcome.pushed;
    return outcome.received;
  }

  /// The downloaded ICAO list, the same on every device but with other ids.
  Future<int> addIcaoType(String designator) => db
      .into(db.icaoAircrafts)
      .insert(
        IcaoAircraftsCompanion.insert(
          modelFullName: '$designator model',
          designator: designator,
          wakeTurbolenceCategory: WakeTurbulenceCategory.L,
          wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
          manufacturer: 'Maker',
          description: AircraftDescription.landplane,
          engineCount: 1,
          engineType: EngineType.piston,
        ),
      );

  Future<Flight?> flight(String title) => (db.select(
    db.flights,
  )..where((f) => f.title.equals(title))).getSingleOrNull();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory root;
  late FakeFolder folder;
  late Device a;
  late Device b;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('zenith_sync');
    folder = FakeFolder();
    a = Device('aaaa', root);
    b = Device('bbbb', root);
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await root.delete(recursive: true);
  });

  /// Logs on [d] a flight in a new aircraft, with a crew member and a track.
  Future<int> logFlight(Device d, String title) async {
    final db = d.db;
    await d.addIcaoType('ZZZZ'); // another type first: ids differ
    final type = await d.addIcaoType('C172');
    final aircraft = await db
        .into(db.aircrafts)
        .insert(
          AircraftsCompanion.insert(icaoAircraft: type, tailNumber: 'I-ABCD'),
        );
    final photoDir = await d.photos.directory;
    File('${photoDir.path}/anna.jpg').writeAsBytesSync([1, 2, 3]);
    final person = await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            name: 'Anna',
            surname: 'Verdi',
            photo: const Value('anna.jpg'),
          ),
        );
    final flight = await db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: title,
            departureTime: DateTime.utc(2026, 5, 1, 10),
            arrivalTime: Value(DateTime.utc(2026, 5, 1, 11)),
            isRecording: false,
            aircraftId: Value(aircraft),
            departure: const Value(1234), // an OurAirports airport
          ),
        );
    await db.setFlightCrew(flight, [
      CrewMember(
        person: await (db.select(
          db.people,
        )..where((p) => p.id.equals(person))).getSingle(),
        role: CrewRole.values.first,
      ),
    ]);
    for (var i = 0; i < 3; i++) {
      await db
          .into(db.flightDataPoints)
          .insert(
            FlightDataPointsCompanion.insert(
              flight: flight,
              longitude: 8.7,
              latitude: 45.6 + i / 100,
              altitude: 100 * i,
              timestamp: DateTime.utc(2026, 5, 1, 10, i),
            ),
          );
    }
    return flight;
  }

  test('a flight logged on one device appears on the other, whole', () async {
    await b.addIcaoType('C172');
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    expect(await b.syncWith(folder), greaterThan(0));

    final flight = (await b.flight('VFR'))!;
    expect(flight.departure, 1234);
    final aircraft = await (b.db.select(
      b.db.aircrafts,
    )..where((x) => x.id.equals(flight.aircraftId!))).getSingle();
    expect(aircraft.tailNumber, 'I-ABCD');
    final type = await (b.db.select(
      b.db.icaoAircrafts,
    )..where((t) => t.id.equals(aircraft.icaoAircraft))).getSingle();
    expect(type.designator, 'C172');

    final crew = await b.db.getFlightCrew(flight.id);
    expect(crew.single.person.name, 'Anna');
    final track = await (b.db.select(
      b.db.flightDataPoints,
    )..where((p) => p.flight.equals(flight.id))).get();
    expect(track.map((p) => p.altitude), [0, 100, 200]);
    final photo = File(
      '${(await b.photos.directory).path}/${crew.single.person.photo}',
    );
    expect(photo.readAsBytesSync(), [1, 2, 3]);

    // Applying didn't make the rows B's own changes.
    expect(await a.syncWith(folder), 0);
  });

  test('edits and deletions travel back; the latest edit wins', () async {
    await b.addIcaoType('C172');
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);

    final onB = (await b.flight('VFR'))!;
    await (b.db.update(b.db.flights)..where((f) => f.id.equals(onB.id))).write(
      const FlightsCompanion(remarks: Value('older')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final onA = (await a.flight('VFR'))!;
    await (a.db.update(a.db.flights)..where((f) => f.id.equals(onA.id))).write(
      const FlightsCompanion(remarks: Value('newer')),
    );

    await b.syncWith(folder);
    await a.syncWith(folder);
    await b.syncWith(folder);
    expect((await a.flight('VFR'))!.remarks, 'newer');
    expect((await b.flight('VFR'))!.remarks, 'newer');

    await b.db.deleteFlight(onB.id);
    await b.syncWith(folder);
    await a.syncWith(folder);
    expect(await a.flight('VFR'), isNull);
    expect(
      await a.db.select(a.db.flightDataPoints).get(),
      isEmpty,
      reason: 'the track goes with the flight',
    );
    expect(
      folder.files.keys.where((n) => n.startsWith('track_')),
      isEmpty,
      reason: 'the cloud copy of the track too',
    );
  });

  test('old deletions stop travelling, and stay deletions', () async {
    await b.addIcaoType('C172');
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);
    await a.syncWith(folder);
    // Both had the flight long ago.
    final days = SyncService.horizon.inMilliseconds;
    for (final d in [a, b]) {
      await d.db.customStatement('UPDATE sync_rows SET stamp = stamp - ?', [
        2 * days,
      ]);
    }

    // a deleted it long ago; b missed that, like a device left in a drawer.
    await a.db.deleteFlight((await a.flight('VFR'))!.id);
    await a.db.customStatement(
      'UPDATE sync_rows SET stamp = stamp - ? WHERE deleted = 1',
      [days + 1000],
    );
    await a.syncWith(folder);
    final state = folder.files.entries.singleWhere(
      (f) => f.key.startsWith('state_aaaa_'),
    );
    final rows =
        (jsonDecode(utf8.decode(gzip.decode(state.value))) as Map)['rows']
            as List;
    expect([
      for (final r in rows)
        if (r['x'] != null) r,
    ], isEmpty);

    await b.syncWith(folder);
    expect(await b.flight('VFR'), isNotNull);
    await a.syncWith(folder);
    expect(await a.flight('VFR'), isNull, reason: 'b sent it back');
  });

  test("a silent device's state is deleted; it comes back", () async {
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);
    final old = folder.files.keys.singleWhere(
      (n) => n.startsWith('state_bbbb_'),
    );
    folder.created[old] = DateTime.now().subtract(
      SyncService.horizon + const Duration(days: 1),
    );

    await a.syncWith(folder);
    expect(
      folder.files.keys.where((n) => n.startsWith('state_bbbb_')),
      isEmpty,
    );
    await b.syncWith(folder);
    expect(folder.files.keys.where((n) => n.startsWith('state_bbbb_')), [
      isNot(old),
    ]);
  });

  test('local changes counts edits made here, not received ones', () async {
    final before = await a.sync.localChanges();
    await logFlight(a, 'VFR');
    final logged = await a.sync.localChanges();
    expect(logged, isNot(before));
    await a.syncWith(folder);

    final unchanged = await b.sync.localChanges();
    await b.syncWith(folder);
    expect(await b.sync.localChanges(), unchanged);

    await a.db
        .into(a.db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'REC',
            departureTime: DateTime.utc(2026, 6),
            isRecording: true,
          ),
        );
    expect(await a.sync.localChanges(), logged);
  });

  test('a flight being recorded stays on its device', () async {
    await a.db
        .into(a.db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'REC',
            departureTime: DateTime.utc(2026, 5),
            isRecording: true,
          ),
        );
    await a.syncWith(folder);
    await b.syncWith(folder);
    expect(await b.flight('REC'), isNull);
  });

  test('an aircraft waits for its ICAO type to be downloaded', () async {
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);
    expect(await b.flight('VFR'), isNull, reason: 'it waits for its aircraft');

    await b.addIcaoType('C172');
    await b.syncWith(folder);
    expect((await b.flight('VFR'))!.aircraftId, isNotNull);
  });

  test('renaming a custom type renames it for the aircraft using it', () async {
    final type = await a.db.addIcaoAircraft(
      modelFullName: 'Homebuilt',
      manufacturer: 'Me',
      designator: 'HB1',
      wakeTurbolenceCategory: WakeTurbulenceCategory.L,
      wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
      description: AircraftDescription.landplane,
      engineCount: 1,
      engineType: EngineType.piston,
    );
    await a.db
        .into(a.db.aircrafts)
        .insert(
          AircraftsCompanion.insert(icaoAircraft: type, tailNumber: 'I-HOME'),
        );
    await a.syncWith(folder);
    await b.syncWith(folder);

    await (a.db.update(a.db.icaoAircrafts)..where((t) => t.id.equals(type)))
        .write(const IcaoAircraftsCompanion(designator: Value('HB2')));
    await a.syncWith(folder);
    await b.syncWith(folder);

    final custom = await (b.db.select(
      b.db.icaoAircrafts,
    )..where((t) => t.userInserted.equals(true))).get();
    expect(custom.map((t) => t.designator), ['HB2']);
    final aircraft = await b.db.select(b.db.aircrafts).getSingle();
    expect(aircraft.icaoAircraft, custom.single.id);
  });

  test('the same things entered on both devices become one', () async {
    for (final d in [a, b]) {
      await d.addIcaoType('C172');
      final type = await d.addIcaoType('C172');
      final aircraft = await d.db
          .into(d.db.aircrafts)
          .insert(
            AircraftsCompanion.insert(icaoAircraft: type, tailNumber: 'I-ABCD'),
          );
      final person = await d.db
          .into(d.db.people)
          .insert(PeopleCompanion.insert(name: 'Anna', surname: 'Verdi'));
      final flight = await d.db
          .into(d.db.flights)
          .insert(
            FlightsCompanion.insert(
              title: 'VFR',
              departureTime: DateTime.utc(2026, 5, 1, 10),
              isRecording: false,
              aircraftId: Value(aircraft),
            ),
          );
      await d.db.setFlightCrew(flight, [
        CrewMember(
          person: await (d.db.select(
            d.db.people,
          )..where((p) => p.id.equals(person))).getSingle(),
          role: CrewRole.values.first,
        ),
      ]);
    }
    // "Anna Bianchi" on B is someone else.
    await b.db
        .into(b.db.people)
        .insert(PeopleCompanion.insert(name: 'Anna', surname: 'Bianchi'));

    for (var i = 0; i < 2; i++) {
      await a.syncWith(folder);
      await b.syncWith(folder);
    }

    for (final d in [a, b]) {
      expect(await d.db.select(d.db.aircrafts).get(), hasLength(1));
      expect(
        (await d.db.select(d.db.people).get()).map((p) => p.surname).toSet(),
        {'Verdi', 'Bianchi'},
      );
      final flights = await d.db.select(d.db.flights).get();
      expect(flights, hasLength(1));
      expect(await d.db.getFlightCrew(flights.single.id), hasLength(1));
    }
    expect(
      (await a.flight('VFR'))!.syncId,
      (await b.flight('VFR'))!.syncId,
      reason: 'one name on both devices',
    );
  });

  test('an edit made while a sync downloads is kept', () async {
    await b.addIcaoType('C172');
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);
    Future<void> remark(Device d, String text) =>
        d.db.update(d.db.flights).write(FlightsCompanion(remarks: Value(text)));

    await remark(a, 'theirs');
    await a.db
        .update(a.db.flightDataPoints)
        .write(const FlightDataPointsCompanion(altitude: Value(5)));
    await a.syncWith(folder);
    var edited = false;
    folder.onDownload = (id) async {
      if (edited || !id.startsWith('track_')) return;
      edited = true;
      await remark(b, 'ours');
    };
    await b.syncWith(folder);
    expect(edited, isTrue);
    await a.syncWith(folder);

    expect((await a.flight('VFR'))!.remarks, 'ours');
    expect((await b.flight('VFR'))!.remarks, 'ours');
  });

  // Deleted on a while b starts using it: whichever syncs first, it stays.
  for (final bFirst in [true, false]) {
    final who = bFirst ? 'b' : 'a';

    Future<void> settle() async {
      if (bFirst) await b.syncWith(folder);
      for (var i = 0; i < 3; i++) {
        await a.syncWith(folder);
        await b.syncWith(folder);
      }
      // Nothing is left waiting, to be read again at every sync.
      final downloads = <String>[];
      folder.onDownload = (id) async => downloads.add(id);
      await a.syncWith(folder);
      await b.syncWith(folder);
      expect(downloads, isEmpty);
    }

    Future<void> log(Device d, FlightsCompanion Function() flight) =>
        d.db.into(d.db.flights).insert(flight());

    FlightsCompanion flight({int? departure, int? aircraft, int? simulator}) =>
        FlightsCompanion.insert(
          title: 'VFR',
          departureTime: DateTime.utc(2026, 5, 1, 10),
          isRecording: false,
          departure: Value(departure),
          aircraftId: Value(aircraft),
          simulatorId: Value(simulator),
        );

    test('a simulator in use elsewhere comes back ($who first)', () async {
      await a.db
          .into(a.db.simulators)
          .insert(SimulatorsCompanion.insert(kind: SimulatorKind.values.first));
      await a.syncWith(folder);
      await b.syncWith(folder);
      final onB = await b.db.select(b.db.simulators).getSingle();
      await log(b, () => flight(simulator: onB.id));
      await a.db.delete(a.db.simulators).go();
      await settle();

      for (final d in [a, b]) {
        final simulator = await d.db.select(d.db.simulators).getSingle();
        expect((await d.flight('VFR'))!.simulatorId, simulator.id);
      }
    });

    test('a custom type in use elsewhere comes back ($who first)', () async {
      await a.db.addIcaoAircraft(
        modelFullName: 'Homebuilt',
        manufacturer: 'Me',
        designator: 'HB1',
        wakeTurbolenceCategory: WakeTurbulenceCategory.L,
        wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
        description: AircraftDescription.landplane,
        engineCount: 1,
        engineType: EngineType.piston,
      );
      await a.syncWith(folder);
      await b.syncWith(folder);
      final onB = await b.db.select(b.db.icaoAircrafts).getSingle();
      final aircraft = await b.db
          .into(b.db.aircrafts)
          .insert(
            AircraftsCompanion.insert(
              icaoAircraft: onB.id,
              tailNumber: 'I-HOME',
            ),
          );
      await log(b, () => flight(aircraft: aircraft));
      await a.db.delete(a.db.icaoAircrafts).go();
      await settle();

      for (final d in [a, b]) {
        final type = await d.db.select(d.db.icaoAircrafts).getSingle();
        final aircraft = await d.db.select(d.db.aircrafts).getSingle();
        expect(aircraft.icaoAircraft, type.id);
        expect((await d.flight('VFR'))!.aircraftId, aircraft.id);
      }
    });

    test('an airport in use elsewhere comes back ($who first)', () async {
      await a.db.customStatement(
        'INSERT INTO airports (id, ident, name, type, continent, iso_country, '
        "iso_region, sync_id) VALUES (-1, 'XFLD', 'Field', 0, 'EU', 'IT', "
        "'IT-25', 'field')",
      );
      await a.syncWith(folder);
      await b.syncWith(folder);
      final onB = await b.db.select(b.db.airports).getSingle();
      await log(b, () => flight(departure: onB.id));
      await a.db.delete(a.db.airports).go();
      await settle();

      for (final d in [a, b]) {
        final airport = await d.db.select(d.db.airports).getSingle();
        expect((await d.flight('VFR'))!.departure, airport.id);
      }
    });
  }

  test('deleting an aircraft still detaches it from its flights', () async {
    await b.addIcaoType('C172');
    await logFlight(a, 'VFR');
    await a.syncWith(folder);
    await b.syncWith(folder);
    await b.db
        .update(b.db.flights)
        .write(const FlightsCompanion(remarks: Value('flown')));
    await a.db.delete(a.db.aircrafts).go();
    for (var i = 0; i < 2; i++) {
      await a.syncWith(folder);
      await b.syncWith(folder);
    }

    for (final d in [a, b]) {
      expect(await d.db.select(d.db.aircrafts).get(), isEmpty);
      expect((await d.flight('VFR'))!.aircraftId, isNull);
    }
  });

  test('a namesake is merged once; the other keeps its flights', () async {
    Future<int> person(Device d, String id) => d.db
        .into(d.db.people)
        .insert(
          PeopleCompanion.insert(
            name: 'Mario',
            surname: 'Rossi',
            syncId: Value(id),
          ),
        );
    await person(a, '0a');
    for (final (day, id) in ['1b', '2b'].indexed) {
      final mario = await person(b, id);
      final flight = await b.db
          .into(b.db.flights)
          .insert(
            FlightsCompanion.insert(
              title: id,
              departureTime: DateTime.utc(2026, 5, day + 1),
              isRecording: false,
            ),
          );
      await b.db
          .into(b.db.flightCrew)
          .insert(
            FlightCrewCompanion.insert(
              flight: flight,
              person: mario,
              role: CrewRole.values.first,
            ),
          );
    }
    await b.syncWith(folder);
    for (var i = 0; i < 2; i++) {
      await a.syncWith(folder);
      await b.syncWith(folder);
    }

    for (final d in [a, b]) {
      final crew = await d.db
          .customSelect(
            'SELECT p.sync_id AS person FROM flights f '
            'JOIN flight_crew c ON c.flight = f.id '
            'JOIN people p ON p.id = c.person ORDER BY f.title',
          )
          .get();
      expect(crew.map((r) => r.read<String>('person')), ['0a', '2b']);
    }
  });

  test('stamps follow the cloud clock, not the device clock', () async {
    folder.ahead = const Duration(hours: 1);
    await a.syncWith(folder);
    await a.syncWith(folder);
    await a.db
        .into(a.db.people)
        .insert(PeopleCompanion.insert(name: 'Anna', surname: 'Verdi'));

    final stamp = await a.db
        .customSelect("SELECT stamp FROM sync_rows WHERE entity = 'people'")
        .getSingle();
    final ahead =
        stamp.read<int>('stamp') - DateTime.now().millisecondsSinceEpoch;
    expect(ahead, closeTo(const Duration(hours: 1).inMilliseconds, 60000));
  });

  test('replaced pictures are deleted, here and in the cloud', () async {
    final dir = await a.photos.directory;
    File('${dir.path}/old.jpg').writeAsBytesSync([1]);
    await a.db
        .into(a.db.people)
        .insert(
          PeopleCompanion.insert(
            name: 'Anna',
            surname: 'Verdi',
            photo: const Value('old.jpg'),
          ),
        );
    await a.syncWith(folder);
    await b.syncWith(folder);
    final onB = File('${(await b.photos.directory).path}/old.jpg');
    expect(onB.existsSync(), isTrue);

    File('${dir.path}/new.jpg').writeAsBytesSync([2]);
    await a.db
        .update(a.db.people)
        .write(const PeopleCompanion(photo: Value('new.jpg')));
    await a.photos.delete('old.jpg');
    folder.created['file_old.jpg'] = DateTime.now().subtract(
      const Duration(days: 2),
    );
    await a.syncWith(folder);
    await b.syncWith(folder);

    expect(onB.existsSync(), isFalse);
    expect(
      File('${(await b.photos.directory).path}/new.jpg').readAsBytesSync(),
      [2],
    );
    expect(folder.files.keys, isNot(contains('file_old.jpg')));
    expect(folder.files.keys, contains('file_new.jpg'));
  });
}
