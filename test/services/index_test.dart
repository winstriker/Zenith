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
}
