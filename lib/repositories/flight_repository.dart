import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../models/flight_track.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// Flights, their tracks and the recording in progress.
class FlightRepository {
  FlightRepository(this._database);
  final LogbookDatabase _database;

  /// Every recorded flight and simulator session, newest first, as they
  /// are now: what the logbook export and "delete all" work on.
  Future<List<FlightWithStats>> allRecordedFlights() => _watchFlights(
    where: _database.flights.isRecording.equals(false),
    limit: null,
  ).first;

  /// The newest [limit] recorded flights that match [query] (see
  /// `sqlMatchesAllTokens`) and, when given, departed on the local [day].
  /// Newest first; a list grows into older flights by asking a bigger
  /// [limit].
  Stream<List<FlightWithStats>> watchRecordedFlightsPage({
    required int limit,
    String query = '',
    DateTime? day,
  }) {
    final flights = _database.flights;
    final tokens = searchTokens(query);
    return _watchFlights(
      where: flights.isRecording.equals(false),
      matching: (dep, arr, aircraft, simulator, simulatorType) =>
          Expression.and([
            if (day != null) ...[
              flights.departureTime.isBiggerOrEqualValue(
                DateTime(day.year, day.month, day.day),
              ),
              flights.departureTime.isSmallerThanValue(
                DateTime(day.year, day.month, day.day + 1),
              ),
            ],
            sqlMatchesAllTokens(tokens, [
              flights.title,
              flights.remarks,
              for (final airport in [dep, arr]) ...[
                airport.ident,
                airport.icaoCode,
                airport.iataCode,
                airport.name,
                airport.municipality,
              ],
              aircraft.tailNumber,
              aircraft.modelFullName,
              aircraft.designator,
              simulator.typeRating,
              simulator.qualificationNumber,
              simulator.organisation,
              simulatorType.designator,
              simulatorType.modelFullName,
            ]),
          ]),
      limit: limit,
    );
  }

  /// How many recorded flights there are, simulator sessions aside.
  Stream<int> watchRecordedFlightCount() {
    final count = _database.flights.id.count();
    final query = _database.selectOnly(_database.flights)
      ..addColumns([count])
      ..where(
        _database.flights.isRecording.equals(false) &
            _database.flights.simulatorId.isNull(),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// The flight being recorded, if any: recording and with no end yet.
  Future<Flight?> activeRecording() {
    return (_database.select(_database.flights)
          ..where((f) => f.isRecording.equals(true) & f.arrivalTime.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  /// Temporary flights: recorded, but not yet completed in the flight form,
  /// so not in the logbook. Newest first.
  Stream<List<FlightWithStats>> watchTemporaryFlights() {
    return _watchFlights(
      where:
          _database.flights.isRecording.equals(true) &
          _database.flights.arrivalTime.isNotNull(),
      limit: null,
    );
  }

  /// The flight with [flightId]; null once deleted.
  Stream<FlightWithStats?> watchFlightById(int flightId) {
    return _watchFlights(
      where: _database.flights.id.equals(flightId),
      limit: 1,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  /// The flights flown with an aircraft, newest first.
  Stream<List<FlightWithStats>> watchFlightsForAircraft(
    int aircraftId, {
    int limit = 5,
    int offset = 0,
  }) {
    return _watchFlights(
      where: _database.flights.aircraftId.equals(aircraftId),
      limit: limit,
      offset: offset,
    );
  }

  /// The flights that departed from or arrived at an airport,
  /// newest first.
  Stream<List<FlightWithStats>> watchFlightsForAirport(
    int airportId, {
    required int limit,
  }) {
    return _watchFlights(
      where:
          _database.flights.departure.equals(airportId) |
          _database.flights.arrival.equals(airportId),
      limit: limit,
    );
  }

  /// The sessions flown in a simulator, newest first.
  Stream<List<FlightWithStats>> watchSessionsForSimulator(
    int simulatorId, {
    int limit = 500,
  }) {
    return _watchFlights(
      where: _database.flights.simulatorId.equals(simulatorId),
      limit: limit,
    );
  }

  /// The flights a person was on as crew, newest first.
  Stream<List<FlightWithStats>> watchFlightsForPerson(
    int personId, {
    int limit = 500,
  }) {
    final crewFlights = _database.selectOnly(_database.flightCrew)
      ..addColumns([_database.flightCrew.flight])
      ..where(_database.flightCrew.person.equals(personId));
    return _watchFlights(
      where: _database.flights.id.isInQuery(crewFlights),
      limit: limit,
    );
  }

  /// Returns the total minutes flown as an [int]. Time in simulators isn't
  /// flight time.
  Stream<int> watchTotalFlightTime() {
    return _database
        .customSelect(
          'SELECT COALESCE(SUM(CAST((arrival_time - departure_time) / 60 '
          'AS INTEGER)), 0) AS total_flight_time FROM flights '
          'WHERE simulator_id IS NULL AND is_recording = 0',
          readsFrom: {_database.flights},
        )
        .watch()
        .map((rows) => rows.first.read<int>('total_flight_time'));
  }

  // Tracks ------------------------------------------------------------------
  //
  // The lists above never load tracks (`dataPoints` stays empty): thousands
  // of rows per flight are only wanted by the one page that draws them.

  SimpleSelectStatement<$FlightDataPointsTable, FlightDataPoint> _trackQuery(
    int flightId,
  ) {
    // Answered straight out of the (flight, timestamp) index, in order.
    return _database.select(_database.flightDataPoints)
      ..where((p) => p.flight.equals(flightId))
      ..orderBy([
        (p) => OrderingTerm.asc(p.timestamp),
        (p) => OrderingTerm.asc(p.id),
      ]);
  }

  /// The track of a flight, in order, as it changes.
  Stream<List<FlightDataPoint>> watchTrack(int flightId) =>
      _trackQuery(flightId).watch();

  /// The track of a flight, in order.
  Future<List<FlightDataPoint>> getTrack(int flightId) =>
      _trackQuery(flightId).get();

  /// Replaces the track of [flightId] with [points], which were fetched
  /// from the ADS-B provider [source] (`AdsbProvider.id`). All or nothing.
  /// Returns how many points were stored.
  Future<int> replaceTrack(
    int flightId,
    List<TrackPoint> points, {
    required String source,
  }) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.flightDataPoints,
      )..where((p) => p.flight.equals(flightId))).go();
      await _database.batch((batch) {
        batch.insertAll(_database.flightDataPoints, [
          for (final point in points)
            FlightDataPointsCompanion.insert(
              flight: flightId,
              longitude: point.longitude,
              latitude: point.latitude,
              altitude: (point.altitude ?? 0).round(),
              timestamp: point.time,
              speed: Value(point.speed),
              heading: Value(point.heading),
            ),
        ]);
      });
      await (_database.update(_database.flights)
            ..where((f) => f.id.equals(flightId)))
          .write(FlightsCompanion(trackSource: Value(source)));
      await _database.updateNightTime(flightId);
      return points.length;
    });
  }

  /// Removes the track of [flightId]. The flight itself stays.
  Future<void> deleteTrack(int flightId) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.flightDataPoints,
      )..where((p) => p.flight.equals(flightId))).go();
      await (_database.update(_database.flights)
            ..where((f) => f.id.equals(flightId)))
          .write(const FlightsCompanion(trackSource: Value(null)));
      await _database.updateNightTime(flightId);
    });
  }

  /// The flights matching [where], with their aircraft, airports and
  /// simulator. [matching] narrows [where] with conditions on the joined departure,
  /// arrival and aircraft.
  Stream<List<FlightWithStats>> _watchFlights({
    required Expression<bool> where,
    Expression<bool> Function(
      $AirportsTable departure,
      $AirportsTable arrival,
      $AircraftWithStatssView aircraft,
      $SimulatorsTable simulator,
      $IcaoAircraftsTable simulatorType,
    )?
    matching,
    // Null: every matching flight.
    int? limit = 10,
    int? offset,
  }) {
    final departure = _database.alias(_database.airports, "dep");
    final arrival = _database.alias(_database.airports, "arr");
    final simulator = _database.simulators;
    final simulatorType = _database.alias(_database.icaoAircrafts, 'sim_type');
    final stat =
        _database.select(_database.flights).join([
            leftOuterJoin(
              _database.aircraftWithStatss,
              _database.flights.aircraftId.equalsExp(
                _database.aircraftWithStatss.id,
              ),
            ),
            leftOuterJoin(
              departure,
              _database.flights.departure.equalsExp(departure.id),
            ),
            leftOuterJoin(
              arrival,
              _database.flights.arrival.equalsExp(arrival.id),
            ),
            leftOuterJoin(
              simulator,
              _database.flights.simulatorId.equalsExp(simulator.id),
            ),
            leftOuterJoin(
              simulatorType,
              simulator.icaoAircraft.equalsExp(simulatorType.id),
            ),
          ])
          ..where(
            matching == null
                ? where
                : where &
                      matching(
                        departure,
                        arrival,
                        _database.aircraftWithStatss,
                        simulator,
                        simulatorType,
                      ),
          )
          ..orderBy([
            OrderingTerm.desc(_database.flights.departureTime),
            // Ties keep their place from one page to the next.
            OrderingTerm.desc(_database.flights.id),
          ]);
    if (limit != null) stat.limit(limit, offset: offset);

    return stat.watch().map(
      (rows) => [
        for (final row in rows)
          FlightWithStats(
            flight: row.readTable(_database.flights),
            dataPoints: const [],
            aircraftWithStats: row.readTableOrNull(
              _database.aircraftWithStatss,
            ),
            simulator: switch (row.readTableOrNull(simulator)) {
              final device? => SimulatorWithStats(
                simulator: device,
                type: row.readTableOrNull(simulatorType),
              ),
              null => null,
            },
            departure: row.readTableOrNull(departure),
            arrival: row.readTableOrNull(arrival),
          ),
      ],
    );
  }

  /// Starts recording a flight: recording, with no arrival time until
  /// [endSession]. Returns its id.
  Future<int> startSession() {
    return _database
        .into(_database.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'Recorded flight',
            departureTime: DateTime.now(),
            isRecording: true,
          ),
        );
  }

  Future<void> addDataPoint({
    required int flightId,
    required double latitude,
    required double longitude,
    required double altitude,
    required DateTime timestamp,
    double? speed,
    double? heading,
  }) async {
    await _database
        .into(_database.flightDataPoints)
        .insert(
          FlightDataPointsCompanion.insert(
            flight: flightId,
            longitude: longitude,
            latitude: latitude,
            altitude: altitude.round(),
            timestamp: timestamp,
            speed: Value(speed),
            heading: Value(heading),
          ),
        );
  }

  /// Ends the recording of [flightId], which stays a temporary flight
  /// spanning its first and last positions. A flight without any position
  /// is deleted. Returns whether the flight was kept.
  Future<bool> endSession(int flightId) {
    return _database.transaction(() async {
      final track = await getTrack(flightId);
      if (track.isEmpty) {
        await deleteSession(flightId);
        return false;
      }
      await (_database.update(
        _database.flights,
      )..where((f) => f.id.equals(flightId))).write(
        FlightsCompanion(
          departureTime: Value(track.first.timestamp),
          arrivalTime: Value(track.last.timestamp),
        ),
      );
      await _database.updateNightTime(flightId);
      return true;
    });
  }

  /// Replaces the logbook overrides of [flightId]; empty ones are removed.
  Future<void> setLogbookOverrides(
    int flightId,
    LogbookOverrides overrides,
  ) async {
    await (_database.update(
      _database.flights,
    )..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(
        logbookOverrides: Value(overrides.isEmpty ? null : overrides),
      ),
    );
  }

  /// Deletes a flight with its track and crew. Flights saved from the form
  /// may have a signature: delete those with `FlightService.deleteSession`.
  Future<void> deleteSession(int sessionId) =>
      _database.deleteFlight(sessionId);
}

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FlightRepository(db);
});
