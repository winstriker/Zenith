import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Set<String>> indexes(LogbookDatabase db) async => {
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name NOT LIKE 'sqlite_%'",
            )
            .get())
      row.read<String>('name'),
  };

  final expected = {
    'airports_lat_lon_idx',
    'airports_iso_country_idx',
    'airports_icao_idx',
    'airports_iata_idx',
    'frequencies_airport_idx',
    'runways_airport_idx',
    'flights_simulator_id_idx',
    'flights_departure_time_idx',
    'flights_aircraft_id_idx',
    'flights_departure_idx',
    'flights_arrival_idx',
    'flight_crew_person_idx',
    'flight_data_points_flight_timestamp_idx',
    'licence_ratings_licence_idx',
  };

  test('a new database has every index', () async {
    final db = LogbookDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await indexes(db), expected);
  });

  test('v17 → v18 creates the missing indexes', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v18');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    final v17 = LogbookDatabase(NativeDatabase(file));
    for (final name in await indexes(v17)) {
      if (name != 'airports_lat_lon_idx') {
        await v17.customStatement('DROP INDEX $name');
      }
    }
    await v17.customStatement('PRAGMA user_version = 17');
    await v17.close();

    final db = LogbookDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await indexes(db), expected);
  });
}
