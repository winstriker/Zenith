import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late FlightRepository repo;
  setUp(() {
    db = LogbookDatabase(NativeDatabase.memory());
    repo = FlightRepository(db);
  });
  tearDown(() => db.close());

  Future<int> addFlight(
    String title,
    DateTime departure, {
    bool recording = false,
    String? remarks,
  }) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: title,
          departureTime: departure,
          isRecording: recording,
          remarks: Value(remarks),
        ),
      );

  Future<List<String>> titles({
    required int limit,
    String query = '',
    DateTime? day,
  }) async => [
    for (final f
        in await repo
            .watchRecordedFlightsPage(limit: limit, query: query, day: day)
            .first)
      f.flight.title,
  ];

  test('pages grow from the newest flights into older ones', () async {
    for (var day = 1; day <= 5; day++) {
      await addFlight('F$day', DateTime(2026, 3, day, 10));
    }
    await addFlight('Recording', DateTime(2026, 3, 9), recording: true);

    expect(await titles(limit: 2), ['F5', 'F4']);
    expect(await titles(limit: 4), ['F5', 'F4', 'F3', 'F2']);
    // Fewer than asked: the list has reached the oldest flight.
    expect(await titles(limit: 6), ['F5', 'F4', 'F3', 'F2', 'F1']);
    expect(await repo.watchRecordedFlightCount().first, 5);
  });

  test('flights departed at the same time keep their order', () async {
    final t = DateTime(2026, 3, 1, 10);
    for (var i = 0; i < 4; i++) {
      await addFlight('F$i', t);
    }
    final firstPage = await titles(limit: 2);
    final both = await titles(limit: 4);
    expect(both.take(2), firstPage);
    expect(both.toSet(), {'F0', 'F1', 'F2', 'F3'});
  });

  test('search and day filter run before the page is cut', () async {
    for (var i = 0; i < 10; i++) {
      await addFlight('Circuit $i', DateTime(2026, 3, 10, 8 + i));
    }
    await addFlight('Old', DateTime(2026, 1, 2, 23, 30), remarks: 'LIMC');
    await addFlight('Next day', DateTime(2026, 1, 3, 0, 10));

    // The match is older than the first page of all flights.
    expect(await titles(limit: 3, query: 'limc'), ['Old']);
    expect(await titles(limit: 3, day: DateTime(2026, 1, 2)), ['Old']);
    expect(await titles(limit: 3, day: DateTime(2026, 1, 3)), ['Next day']);
    expect(await titles(limit: 3, query: 'circuit 9'), ['Circuit 9']);
  });

  test('the logbook export gets every flight, not a page', () async {
    final start = DateTime(2024, 1, 1, 10);
    for (var i = 0; i < 650; i++) {
      await addFlight('F$i', start.add(Duration(days: i)));
    }
    await addFlight('Recording', DateTime(2026, 11), recording: true);
    final all = await repo.allRecordedFlights();
    expect(all, hasLength(650));
    expect(all.first.flight.title, 'F649');
    expect(all.last.flight.title, 'F0');
  });

  test(
    'airport pages hold its departures and arrivals, newest first',
    () async {
      Future<void> fly(String title, int day, {int? from, int? to}) => db
          .into(db.flights)
          .insert(
            FlightsCompanion.insert(
              title: title,
              departureTime: DateTime(2026, 3, day, 10),
              isRecording: false,
              departure: Value(from),
              arrival: Value(to),
            ),
          );
      await fly('Out', 1, from: 1, to: 2);
      await fly('In', 2, from: 2, to: 1);
      await fly('Elsewhere', 3, from: 2, to: 3);
      await fly('Local', 4, from: 1, to: 1);

      Future<List<String>> page(int limit) async => [
        for (final f
            in await repo.watchFlightsForAirport(1, limit: limit).first)
          f.flight.title,
      ];
      expect(await page(2), ['Local', 'In']);
      expect(await page(20), ['Local', 'In', 'Out']);
    },
  );
}
