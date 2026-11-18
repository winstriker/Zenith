import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('v12 → v13 adds the new columns and retires EIRs', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v13');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    final v13 = LogbookDatabase(NativeDatabase(file));
    final licence = await v13
        .into(v13.licences)
        .insert(
          LicencesCompanion.insert(
            kind: LicenceKind.ppl,
            category: AircraftCategory.aeroplane,
          ),
        );
    // An EIR as stored before the rating kind was removed.
    await v13.customStatement(
      'INSERT INTO licence_ratings (licence, kind) '
      "VALUES ($licence, 'enRouteInstrument')",
    );
    await v13.customStatement(
      'ALTER TABLE licence_ratings DROP COLUMN light_single_engine',
    );
    await v13.customStatement(
      'ALTER TABLE flights DROP COLUMN mountain_landings',
    );
    await v13.customStatement('ALTER TABLE pilot_profile DROP COLUMN address');
    await v13.customStatement('PRAGMA user_version = 12');
    await v13.close();

    final db = LogbookDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rating = await db.select(db.licenceRatings).getSingle();
    expect(rating.kind, RatingKind.other);
    expect(rating.name, 'EIR');
    expect(rating.lightSingleEngine, isFalse);

    final flight = await db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'A → B',
            departureTime: DateTime.utc(2026, 11, 1, 9),
            isRecording: false,
            mountainLandings: const Value(2),
          ),
        );
    expect(
      (await (db.select(
        db.flights,
      )..where((f) => f.id.equals(flight))).getSingle()).mountainLandings,
      2,
    );
    await db
        .into(db.pilotProfile)
        .insert(
          PilotProfileCompanion.insert(
            id: const Value(PilotProfile.rowId),
            address: const Value('Via Roma 1'),
          ),
        );
    expect(
      (await db.select(db.pilotProfile).getSingle()).address,
      'Via Roma 1',
    );
  });

  test('v13 → v14 adds the aircraft logbook entry', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v14');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    final v14 = LogbookDatabase(NativeDatabase(file));
    final type = await v14
        .into(v14.icaoAircrafts)
        .insert(
          IcaoAircraftsCompanion.insert(
            modelFullName: '747-400',
            designator: 'B744',
            wakeTurbolenceCategory: WakeTurbulenceCategory.H,
            wakeTurbolenceGroup: WakeTurbulenceGroup.B,
            manufacturer: 'BOEING',
            description: AircraftDescription.landplane,
            engineCount: 4,
            engineType: EngineType.jet,
          ),
        );
    final id = await v14
        .into(v14.aircrafts)
        .insert(
          AircraftsCompanion.insert(icaoAircraft: type, tailNumber: 'D-ABVM'),
        );
    // The views read the new columns: they go first.
    for (final view in ['aircraft_with_statss', 'aircraft_with_icaos']) {
      await v14.customStatement('DROP VIEW IF EXISTS $view');
    }
    for (final column in ['logbook_type', 'logbook_subtitle']) {
      await v14.customStatement('ALTER TABLE aircrafts DROP COLUMN $column');
    }
    await v14.customStatement('PRAGMA user_version = 13');
    await v14.close();

    final db = LogbookDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await (db.update(db.aircrafts)..where((a) => a.id.equals(id))).write(
      const AircraftsCompanion(
        logbookType: Value('B747'),
        logbookSubtitle: Value('747-400'),
      ),
    );
    final aircraft = await (db.select(
      db.aircraftWithStatss,
    )..where((a) => a.id.equals(id))).getSingle();
    expect(aircraft.logbookTypeLine, 'B747');
    expect(aircraft.logbookSubtitleLine, '747-400');
  });
}
