import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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
