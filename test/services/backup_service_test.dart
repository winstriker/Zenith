import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/backup_service.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';

IcaoAircraftsCompanion _icao(String designator) =>
    IcaoAircraftsCompanion.insert(
      modelFullName: 'Model $designator',
      designator: designator,
      wakeTurbolenceCategory: WakeTurbulenceCategory.L,
      wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
      manufacturer: 'ACME',
      description: AircraftDescription.landplane,
      engineCount: 1,
      engineType: EngineType.piston,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase source;
  late LogbookDatabase target;
  late Directory sourceRoot;
  late Directory targetRoot;
  late BackupService sourceBackup;
  late BackupService targetBackup;

  setUp(() async {
    source = LogbookDatabase(NativeDatabase.memory());
    target = LogbookDatabase(NativeDatabase.memory());
    sourceRoot = await Directory.systemTemp.createTemp('zenith_src');
    targetRoot = await Directory.systemTemp.createTemp('zenith_dst');
    sourceBackup = BackupService(
      source,
      PersonPhotoStore(() async => sourceRoot),
      AircraftPhotoStore(() async => sourceRoot),
      SignatureStore(() async => sourceRoot),
      () async => Directory('${sourceRoot.path}/tmp'),
    );
    targetBackup = BackupService(
      target,
      PersonPhotoStore(() async => targetRoot),
      AircraftPhotoStore(() async => targetRoot),
      SignatureStore(() async => targetRoot),
      () async => Directory('${targetRoot.path}/tmp'),
    );
  });

  tearDown(() async {
    await source.close();
    await target.close();
    await sourceRoot.delete(recursive: true);
    await targetRoot.delete(recursive: true);
  });

  /// One aircraft, one flight with a GPS track and a crew member with photo.
  Future<void> seed() async {
    final icaoId = await source
        .into(source.icaoAircrafts)
        .insert(_icao('C172'));
    final aircraftId = await source
        .into(source.aircrafts)
        .insert(
          AircraftsCompanion.insert(icaoAircraft: icaoId, tailNumber: 'I-ABCD'),
        );
    final flightId = await source
        .into(source.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'LIML → LIPZ',
            departureTime: DateTime.utc(2026, 5, 1, 8),
            arrivalTime: Value(DateTime.utc(2026, 5, 1, 9, 30)),
            isRecording: false,
            aircraftId: Value(aircraftId),
            remarks: const Value('Smooth air ✈️'),
          ),
        );
    for (var i = 0; i < 1500; i++) {
      await source
          .into(source.flightDataPoints)
          .insert(
            FlightDataPointsCompanion.insert(
              flight: flightId,
              longitude: 9.0 + i / 1000,
              latitude: 45.0 + i / 1000,
              altitude: 1000 + i,
              timestamp: DateTime.utc(2026, 5, 1, 8).add(Duration(seconds: i)),
              speed: Value(i * 0.5),
            ),
          );
    }
    final photos = Directory('${sourceRoot.path}/people_photos')
      ..createSync(recursive: true);
    File('${photos.path}/anna.jpg').writeAsBytesSync([1, 2, 3, 4]);
    final personId = await source
        .into(source.people)
        .insert(
          PeopleCompanion.insert(
            name: 'Anna',
            surname: 'Rossi',
            photo: const Value('anna.jpg'),
          ),
        );
    await source
        .into(source.flightCrew)
        .insert(
          FlightCrewCompanion.insert(
            flight: flightId,
            person: personId,
            role: CrewRole.ins,
          ),
        );
  }

  Future<void> seedAirport(LogbookDatabase db, int id, String ident) async {
    await db
        .into(db.countries)
        .insertOnConflictUpdate(
          CountriesCompanion.insert(
            id: const Value(1),
            code: 'IT',
            name: 'Italy',
            continent: 'EU',
          ),
        );
    await db
        .into(db.regions)
        .insertOnConflictUpdate(
          RegionsCompanion.insert(
            id: const Value(1),
            code: 'IT-25',
            name: 'Lombardy',
            continent: 'EU',
            isoCountry: 'IT',
          ),
        );
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            id: Value(id),
            ident: Value(ident),
            type: AirportType.values.first,
            continent: 'EU',
            isoCountry: 'IT',
            isoRegion: 'IT-25',
          ),
        );
  }

  test('round trip restores the whole database and photos', () async {
    await seed();
    await seedAirport(source, 4000, 'LIML');
    // The target has other data, all of which must be replaced.
    await target.into(target.icaoAircrafts).insert(_icao('PA28'));
    await seedAirport(target, 5000, 'XXXX');
    await target
        .into(target.people)
        .insert(PeopleCompanion.insert(name: 'Old', surname: 'Data'));

    final snapshot = await sourceBackup.create(includePhotos: true);
    expect(snapshot.isEmpty, isFalse);
    final summary = await targetBackup.restore(snapshot.bytes);

    expect(summary.flights, 1);
    expect(summary.aircraft, 1);
    expect(summary.people, 1);
    expect(summary.photos, 1);

    final flight = await target.select(target.flights).getSingle();
    expect(flight.title, 'LIML → LIPZ');
    expect(flight.remarks, 'Smooth air ✈️');
    expect(flight.departureTime, DateTime.utc(2026, 5, 1, 8).toLocal());
    expect(flight.arrivalTime, DateTime.utc(2026, 5, 1, 9, 30).toLocal());

    final points = await target.select(target.flightDataPoints).get();
    expect(points, hasLength(1500));
    expect(points.last.speed, 1499 * 0.5);

    final aircraft = await target.select(target.aircrafts).getSingle();
    final icao = await (target.select(
      target.icaoAircrafts,
    )..where((t) => t.id.equals(aircraft.icaoAircraft))).getSingle();
    expect(icao.designator, 'C172');
    expect(await target.select(target.icaoAircrafts).get(), hasLength(1));

    // Reference data comes back too, not just the logbook.
    final airport = await target.select(target.airports).getSingle();
    expect((airport.id, airport.ident), (4000, 'LIML'));
    expect(await target.select(target.countries).get(), hasLength(1));

    final person = await target.select(target.people).getSingle();
    expect(person.fullName, 'Anna Rossi');
    expect(
      File('${targetRoot.path}/people_photos/anna.jpg').readAsBytesSync(),
      [1, 2, 3, 4],
    );
    final crew = await target.getFlightCrew(flight.id);
    expect(crew.single.role, CrewRole.ins);
  });

  test(
    'picked aircraft photos travel with the backup, links stay links',
    () async {
      final icaoId = await source
          .into(source.icaoAircrafts)
          .insert(_icao('C172'));
      final photos = Directory('${sourceRoot.path}/aircraft_photos')
        ..createSync(recursive: true);
      File('${photos.path}/mine.jpg').writeAsBytesSync([9, 8, 7]);
      await source
          .into(source.aircrafts)
          .insert(
            AircraftsCompanion.insert(
              icaoAircraft: icaoId,
              tailNumber: 'I-FILE',
              photoFile: const Value('mine.jpg'),
              aircraftClass: const Value(AircraftClass.sepLand),
            ),
          );
      await source
          .into(source.aircrafts)
          .insert(
            AircraftsCompanion.insert(
              icaoAircraft: icaoId,
              tailNumber: 'I-LINK',
              photoUrl: const Value('https://cdn.jetphotos.com/full/1/a.jpg'),
              photoLink: const Value('https://www.jetphotos.com/photo/1'),
            ),
          );
      // A leftover in the target that no restored aircraft uses.
      final targetPhotos = Directory('${targetRoot.path}/aircraft_photos')
        ..createSync(recursive: true);
      File('${targetPhotos.path}/stale.jpg').writeAsBytesSync([0]);

      final withPhotos = await sourceBackup.create(includePhotos: true);
      final summary = await targetBackup.restore(withPhotos.bytes);

      expect(summary.photos, 1);
      expect(File('${targetPhotos.path}/mine.jpg').readAsBytesSync(), [
        9,
        8,
        7,
      ]);
      expect(File('${targetPhotos.path}/stale.jpg').existsSync(), isFalse);
      var aircraft = {
        for (final a in await target.select(target.aircrafts).get())
          a.tailNumber: a,
      };
      expect(aircraft['I-FILE']!.photoFile, 'mine.jpg');
      expect(aircraft['I-FILE']!.aircraftClass, AircraftClass.sepLand);
      expect(
        aircraft['I-LINK']!.photoUrl,
        'https://cdn.jetphotos.com/full/1/a.jpg',
      );
      expect(
        aircraft['I-LINK']!.photoLink,
        'https://www.jetphotos.com/photo/1',
      );

      // Restored without photos on a device that doesn't have the file, the
      // picked photo is cleared; links need no file.
      File('${targetPhotos.path}/mine.jpg').deleteSync();
      final withoutPhotos = await sourceBackup.create(includePhotos: false);
      await targetBackup.restore(withoutPhotos.bytes);
      aircraft = {
        for (final a in await target.select(target.aircrafts).get())
          a.tailNumber: a,
      };
      expect(aircraft['I-FILE']!.photoFile, isNull);
      expect(aircraft['I-LINK']!.photoUrl, isNotNull);
    },
  );

  test('signatures travel with the backup even without photos', () async {
    await seed();
    final signatures = Directory('${sourceRoot.path}/signatures')
      ..createSync(recursive: true);
    File('${signatures.path}/sig.png').writeAsBytesSync([5, 6, 7]);
    await source
        .update(source.flights)
        .write(const FlightsCompanion(signatureFile: Value('sig.png')));
    // A leftover in the target that no restored flight uses.
    final targetSignatures = Directory('${targetRoot.path}/signatures')
      ..createSync(recursive: true);
    File('${targetSignatures.path}/stale.png').writeAsBytesSync([0]);

    final snapshot = await sourceBackup.create(includePhotos: false);
    await targetBackup.restore(snapshot.bytes);

    final flight = await target.select(target.flights).getSingle();
    expect(flight.signatureFile, 'sig.png');
    expect(File('${targetSignatures.path}/sig.png').readAsBytesSync(), [
      5,
      6,
      7,
    ]);
    expect(File('${targetSignatures.path}/stale.png').existsSync(), isFalse);
  });

  test('without photos, missing pictures are cleared on restore', () async {
    await seed();
    final snapshot = await sourceBackup.create(includePhotos: false);
    await targetBackup.restore(snapshot.bytes);
    final person = await target.select(target.people).getSingle();
    expect(person.photo, isNull);
  });

  test('identical data gives the same content hash', () async {
    await seed();
    final a = await sourceBackup.create(includePhotos: true);
    final b = await sourceBackup.create(includePhotos: true);
    expect(a.contentHash, b.contentHash);
    final c = await sourceBackup.create(includePhotos: false);
    expect(c.contentHash, isNot(a.contentHash));
  });

  test('snapshot is a zip with manifest and full database', () async {
    await seed();
    await seedAirport(source, 4000, 'LIML');
    final snapshot = await sourceBackup.create(includePhotos: true);
    final header = await BackupService.readHeader(snapshot.bytes);
    expect(header['format'], 'zenith-backup');
    expect(header['schemaVersion'], source.schemaVersion);
    expect(header['counts'], {'flights': 1, 'aircraft': 1, 'people': 1});
    // Scratch files are cleaned up.
    expect(Directory('${sourceRoot.path}/tmp').listSync(), isEmpty);
  });

  test('a failed restore leaves the database untouched', () async {
    await target
        .into(target.people)
        .insert(PeopleCompanion.insert(name: 'Keep', surname: 'Me'));
    expect(
      () => targetBackup.restore(Uint8List.fromList(List.filled(100, 7))),
      throwsA(isA<BackupException>()),
    );
    expect(await target.select(target.people).get(), hasLength(1));
  });

  test('empty logbook is flagged', () async {
    final snapshot = await sourceBackup.create(includePhotos: true);
    expect(snapshot.isEmpty, isTrue);
  });

  test('refuses to restore while a flight is recording', () async {
    await seed();
    final snapshot = await sourceBackup.create(includePhotos: true);
    await target
        .into(target.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'In progress',
            departureTime: DateTime.now(),
            isRecording: true,
          ),
        );
    expect(
      () => targetBackup.restore(snapshot.bytes),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects files that are not backups', () async {
    expect(
      () => targetBackup.restore(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => BackupService.readHeader(Uint8List.fromList('{"a":1}'.codeUnits)),
      throwsA(isA<BackupException>()),
    );
  });

  test('file names round trip to their time', () {
    final t = DateTime(2026, 11, 14, 9, 5, 7);
    final name = BackupService.fileNameFor(t);
    expect(name, 'zenith_backup_20261114_090507.zip');
    expect(BackupService.isBackupFileName(name), isTrue);
    expect(BackupService.timeFromFileName(name), t);
    expect(
      BackupService.timeFromFileName(
        BackupService.fileNameFor(t, suffix: '_pre-restore'),
      ),
      t,
    );
  });
}
