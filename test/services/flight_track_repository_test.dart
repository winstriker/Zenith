import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/flight_service.dart';

final _start = DateTime.utc(2026, 11, 13, 8);

TrackPoint _point(int second, {double altitude = 300}) => TrackPoint(
  time: _start.add(Duration(seconds: second)),
  latitude: 45 + second / 1000,
  longitude: 9,
  altitude: altitude,
  speed: 180.5,
  heading: 90,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late FlightRepository repo;
  setUp(() {
    db = LogbookDatabase(NativeDatabase.memory());
    repo = FlightRepository(db);
  });
  tearDown(() => db.close());

  Future<int> addFlight({String? pilotRole}) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: 'A → B',
          departureTime: _start,
          arrivalTime: Value(_start.add(const Duration(hours: 1))),
          isRecording: false,
          pilotRole: Value(pilotRole),
        ),
      );

  Future<Flight> flight(int id) =>
      (db.select(db.flights)..where((f) => f.id.equals(id))).getSingle();

  test(
    'a fetched track is stored in order, with where it comes from',
    () async {
      final id = await addFlight();
      final other = await addFlight();
      await repo.replaceTrack(other, [_point(0), _point(5)], source: 'opensky');

      final stored = await repo.replaceTrack(id, [
        _point(20, altitude: 500.4),
        _point(0),
        _point(10, altitude: 399.6),
      ], source: 'flyitalyadsb');

      expect(stored, 3);
      final track = await repo.getTrack(id);
      expect(track.map((p) => p.altitude), [300, 400, 500]);
      expect(track.first.timestamp.toUtc(), _start);
      expect(track.first.latitude, 45);
      expect(track.first.speed, 180.5);
      expect(track.first.heading, 90);
      expect((await flight(id)).trackSource, 'flyitalyadsb');
      // The other flight's track is its own.
      expect(await repo.getTrack(other), hasLength(2));
      expect((await flight(other)).trackSource, 'opensky');
    },
  );

  test('fetching again replaces the track', () async {
    final id = await addFlight();
    await repo.replaceTrack(id, [
      _point(0),
      _point(5),
      _point(9),
    ], source: 'opensky');

    await repo.replaceTrack(id, [_point(1), _point(2)], source: 'flyitalyadsb');

    expect(await repo.getTrack(id), hasLength(2));
    expect((await flight(id)).trackSource, 'flyitalyadsb');
  });

  test('watchTrack follows the track as it changes', () async {
    final id = await addFlight();
    final seen = <int>[];
    final subscription = repo.watchTrack(id).listen((t) => seen.add(t.length));
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repo.replaceTrack(id, [_point(0), _point(5)], source: 'opensky');
    await pumpEventQueue();
    await repo.deleteTrack(id);
    await pumpEventQueue();

    expect(seen, [0, 2, 0]);
    expect((await flight(id)).trackSource, isNull);
    // The flight itself is still there.
    expect(await db.select(db.flights).get(), hasLength(1));
  });

  test(
    "a track recorded by the app has no source, and is read the same way",
    () async {
      final id = await repo.startSession();
      for (final second in [0, 2, 1]) {
        await repo.addDataPoint(
          flightId: id,
          latitude: 45,
          longitude: 9,
          altitude: 100.0 + second,
          timestamp: _start.add(Duration(seconds: second)),
        );
      }

      expect((await repo.getTrack(id)).map((p) => p.altitude), [100, 101, 102]);
      expect((await flight(id)).trackSource, isNull);
    },
  );

  test('editing a flight keeps its track and where it comes from', () async {
    final id = await addFlight(pilotRole: 'pic');
    await repo.replaceTrack(id, [_point(0), _point(5)], source: 'opensky');

    await FlightService(db).updateFlight(
      flightId: id,
      departureId: null,
      arrivalId: null,
      title: 'C → D',
      departureTime: _start,
      remarks: 'edited',
      pilotRole: 'sic',
    );

    final edited = await flight(id);
    expect(edited.title, 'C → D');
    expect(edited.remarks, 'edited');
    expect(edited.pilotRole, 'sic');
    expect(edited.trackSource, 'opensky');
    expect(await repo.getTrack(id), hasLength(2));
  });

  test('deleting a flight deletes its track', () async {
    final id = await addFlight();
    await repo.replaceTrack(id, [_point(0), _point(5)], source: 'opensky');

    await repo.deleteSession(id);

    expect(await db.select(db.flightDataPoints).get(), isEmpty);
  });

  test("a flight's track is read through the index, not by scanning", () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM flight_data_points '
          'WHERE flight = 1 ORDER BY timestamp, id',
        )
        .get();
    final detail = plan.map((row) => row.read<String>('detail')).join(' | ');

    expect(detail, contains('flight_data_points_flight_timestamp_idx'));
    expect(detail, isNot(contains('SCAN')));
    expect(detail, isNot(contains('TEMP B-TREE')));
  });

  test(
    'v5 → v6 migration adds the track source and indexes the tracks',
    () async {
      final dir = await Directory.systemTemp.createTemp('zenith_migration_v6');
      final file = File('${dir.path}/db.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      // Build a current database, then take it back to what version 5 had.
      final v6 = LogbookDatabase(NativeDatabase(file));
      final id = await v6
          .into(v6.flights)
          .insert(
            FlightsCompanion.insert(
              title: 'Recorded',
              departureTime: _start,
              isRecording: false,
              pilotRole: const Value('pic'),
            ),
          );
      for (var second = 0; second < 3; second++) {
        await v6
            .into(v6.flightDataPoints)
            .insert(
              FlightDataPointsCompanion.insert(
                flight: id,
                longitude: 9,
                latitude: 45,
                altitude: 100 + second,
                timestamp: _start.add(Duration(seconds: second)),
              ),
            );
      }
      await v6.customStatement(
        'DROP INDEX flight_data_points_flight_timestamp_idx',
      );
      await v6.customStatement('ALTER TABLE flights DROP COLUMN track_source');
      await v6.customStatement('PRAGMA user_version = 5');
      await v6.close();

      final db = LogbookDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final repo = FlightRepository(db);

      // What was there is untouched...
      final migrated = await (db.select(
        db.flights,
      )..where((f) => f.id.equals(id))).getSingle();
      expect(migrated.pilotRole, 'pic');
      expect(migrated.trackSource, isNull);
      expect(await repo.getTrack(id), hasLength(3));
      // ...and the new things work.
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'flight_data_points'",
          )
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')),
        contains('flight_data_points_flight_timestamp_idx'),
      );
      await repo.replaceTrack(id, [_point(0), _point(1)], source: 'opensky');
      expect(
        (await (db.select(
          db.flights,
        )..where((f) => f.id.equals(id))).getSingle()).trackSource,
        'opensky',
      );
    },
  );

  test('a recording becomes a temporary flight, out of the logbook until '
      'completed', () async {
    final id = await repo.startSession();
    expect((await repo.activeRecording())?.id, id);
    for (final second in [0, 600]) {
      await repo.addDataPoint(
        flightId: id,
        latitude: 45,
        longitude: 9,
        altitude: 100,
        timestamp: _start.add(Duration(seconds: second)),
      );
    }

    expect(await repo.endSession(id), isTrue);
    expect(await repo.activeRecording(), isNull);
    final temporary = await repo.watchTemporaryFlights().first;
    expect(temporary.map((f) => f.flight.id), [id]);
    // Spans its first and last positions.
    expect(temporary.single.flight.departureTime.toUtc(), _start);
    expect(
      temporary.single.flight.arrivalTime?.toUtc(),
      _start.add(const Duration(minutes: 10)),
    );
    expect(await repo.allRecordedFlights(), isEmpty);
    expect(await repo.watchTotalFlightTime().first, 0);

    // Saving it from the flight form completes it.
    await FlightService(db).updateFlight(
      flightId: id,
      departureId: null,
      arrivalId: null,
      title: 'A → B',
      departureTime: _start,
      arrivalTime: _start.add(const Duration(minutes: 10)),
    );
    expect(await repo.watchTemporaryFlights().first, isEmpty);
    expect((await repo.allRecordedFlights()).map((f) => f.flight.id), [id]);
    expect(await repo.getTrack(id), hasLength(2));
    expect(await repo.watchTotalFlightTime().first, 10);
  });

  test('a recording without any position is not kept', () async {
    final id = await repo.startSession();
    expect(await repo.endSession(id), isFalse);
    expect(await db.select(db.flights).get(), isEmpty);
  });
}
