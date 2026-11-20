import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> addAirport(LogbookDatabase db, int id, String ident) async {
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            id: Value(id),
            ident: Value(ident),
            type: AirportType.mediumAirport,
            continent: 'EU',
            isoCountry: 'IT',
            isoRegion: 'IT-25',
            latitudeDeg: const Value(45.63),
            longitudeDeg: const Value(8.72),
          ),
        );
  }

  Future<int> addFlight(
    LogbookDatabase db, {
    required String? rules,
    required DateTime dep,
    Duration block = const Duration(hours: 1),
    int? airport,
  }) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: '$rules',
          departureTime: dep,
          arrivalTime: Value(dep.add(block)),
          isRecording: false,
          flightRules: Value(rules),
          departure: Value(airport),
          arrival: Value(airport),
        ),
      );

  test('v6 → v7 works out IFR and night time of the logged flights', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v7');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    final v7 = LogbookDatabase(NativeDatabase(file));
    await addAirport(v7, 1, 'LIMC');
    final day = DateTime.utc(2026, 6, 21, 9);
    final night = DateTime.utc(2026, 12, 21, 19);
    final vfr = await addFlight(v7, rules: 'VFR', dep: day, airport: 1);
    final ifr = await addFlight(v7, rules: 'IFR', dep: night, airport: 1);
    final mixed = await addFlight(v7, rules: 'Y', dep: night, airport: 1);
    final noAirport = await addFlight(v7, rules: null, dep: night);
    for (final column in [
      'instrument_minutes',
      'night_minutes',
      'logbook_overrides',
    ]) {
      await v7.customStatement('ALTER TABLE flights DROP COLUMN $column');
    }
    await v7.customStatement('PRAGMA user_version = 6');
    await v7.close();

    final db = LogbookDatabase(NativeDatabase(file));
    addTearDown(db.close);
    Future<Flight> flight(int id) =>
        (db.select(db.flights)..where((f) => f.id.equals(id))).getSingle();

    expect((await flight(vfr)).instrumentMinutes, 0);
    expect((await flight(vfr)).nightMinutes, 0);
    expect((await flight(ifr)).instrumentMinutes, 60);
    expect((await flight(ifr)).nightMinutes, 60);
    // The split of a Y flight is only known to the pilot.
    expect((await flight(mixed)).instrumentMinutes, isNull);
    expect((await flight(mixed)).nightMinutes, 60);
    expect((await flight(noAirport)).instrumentMinutes, 0);
    expect((await flight(noAirport)).nightMinutes, isNull);
    expect((await flight(vfr)).logbookOverrides, isNull);

    // And overrides can be stored.
    final repo = FlightRepository(db);
    const overrides = LogbookOverrides(
      times: {LogbookTimeField.total: Duration(minutes: 55)},
    );
    await repo.setLogbookOverrides(vfr, overrides);
    expect((await flight(vfr)).logbookOverrides, overrides);
    await repo.setLogbookOverrides(vfr, LogbookOverrides.empty);
    expect((await flight(vfr)).logbookOverrides, isNull);
  });

  group('night time follows the track', () {
    late LogbookDatabase db;
    late FlightRepository repo;
    setUp(() {
      db = LogbookDatabase(NativeDatabase.memory());
      repo = FlightRepository(db);
    });
    tearDown(() => db.close());

    Future<int?> nightOf(int id) async => (await (db.select(
      db.flights,
    )..where((f) => f.id.equals(id))).getSingle()).nightMinutes;

    // Equator, dusk at 0° is ~18:31 UTC; at 90°E it is night all along.
    final dep = DateTime.utc(2026, 3, 20, 16);
    List<TrackPoint> eastTrack() => [
      for (var minute = 10; minute < 230; minute += 10)
        TrackPoint(
          time: dep.add(Duration(minutes: minute)),
          latitude: 0,
          longitude: 90,
        ),
    ];

    test(
      'a fetched track replaces the airports, removing it goes back',
      () async {
        await db
            .into(db.airports)
            .insert(
              AirportsCompanion.insert(
                id: const Value(1),
                type: AirportType.smallAirport,
                continent: 'AF',
                isoCountry: 'GA',
                isoRegion: 'GA-1',
                latitudeDeg: const Value(0),
                longitudeDeg: const Value(0),
              ),
            );
        final id = await addFlight(
          db,
          rules: 'VFR',
          dep: dep,
          block: const Duration(hours: 4),
          airport: 1,
        );
        await db.updateNightTime(id);
        final direct = (await nightOf(id))!;
        expect(direct, inInclusiveRange(85, 93));

        await repo.replaceTrack(id, eastTrack(), source: 'opensky');
        expect(await nightOf(id), greaterThan(direct + 60));

        await repo.deleteTrack(id);
        expect(await nightOf(id), direct);
      },
    );

    test('a recorded flight without airports gets it from its track', () async {
      final id = await repo.startSession();
      for (final p in eastTrack()) {
        await repo.addDataPoint(
          flightId: id,
          latitude: p.latitude,
          longitude: p.longitude,
          altitude: 1000,
          timestamp: DateTime.now(),
        );
      }
      await repo.endSession(id);
      expect(await nightOf(id), isNotNull);
    });
  });
}
