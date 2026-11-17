import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../models/flight_track.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// Repository for flight data access using Drift's reactive queries
class FlightRepository {
  FlightRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of all recorded flights with stats, ordered by departure time descending
  Stream<List<FlightWithStats>> watchRecordedFlights({int limit = 100}) {
    return _watchFlights(
      where: _database.flights.isRecording.equals(false),
      limit: limit,
    );
  }

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
      matching: (dep, arr, aircraft) => Expression.and([
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
        ]),
      ]),
      limit: limit,
    );
  }

  /// How many recorded flights there are.
  Stream<int> watchRecordedFlightCount() {
    final count = _database.flights.id.count();
    final query = _database.selectOnly(_database.flights)
      ..addColumns([count])
      ..where(_database.flights.isRecording.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Stream of active recording session
  Stream<FlightWithStats?> watchActiveFlight() {
    return _watchFlights(
      where: _database.flights.isRecording.equals(true),
      limit: 1,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  /// Stream of a specific flight by ID
  Stream<FlightWithStats?> watchFlightById(int flightId) {
    return _watchFlights(
      where: _database.flights.id.equals(flightId),
      limit: 1,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  /// Stream of flights for a specific aircraft
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

  /// Stream of flights a person was on as crew
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

  /// Returns the total minutes flown as an [int]
  Stream<int> watchTotalFlightTime() {
    return _database
        .customSelect(
          "SELECT COALESCE(SUM(${_database.flightStats.flightTime.escapedNameFor(SqlDialect.sqlite)}), 0) AS total_flight_time FROM ${_database.flightStats.entityName}",
          readsFrom: {_database.flights},
        )
        .watch()
        .map((row) {
          return row.first.read<int>('total_flight_time');
        });
  }

  /// Stream of recent flights (for home page)
  Stream<List<FlightWithStats>> watchRecentFlights({int limit = 20}) {
    return watchRecordedFlights(limit: limit);
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

  /// Internal method to watch flights with joins for related data
  ///
  /// [matching] narrows [where] with conditions on the joined departure,
  /// arrival and aircraft.
  Stream<List<FlightWithStats>> _watchFlights({
    required Expression<bool> where,
    Expression<bool> Function(
      $AirportsTable departure,
      $AirportsTable arrival,
      $AircraftWithStatssView aircraft,
    )?
    matching,
    int limit = 10,
    int? offset,
  }) {
    final departure = _database.alias(_database.airports, "dep");
    final arrival = _database.alias(_database.airports, "arr");
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
          ])
          ..where(
            matching == null
                ? where
                : where &
                      matching(
                        departure,
                        arrival,
                        _database.aircraftWithStatss,
                      ),
          )
          ..orderBy([
            OrderingTerm.desc(_database.flights.departureTime),
            // Ties keep their place from one page to the next.
            OrderingTerm.desc(_database.flights.id),
          ])
          ..limit(limit, offset: offset);

    final flightStream = stat.watch();

    // Transform the flight stream to include related data
    return flightStream.asyncMap((rows) async {
      if (rows.isEmpty) return <FlightWithStats>[];

      return rows.map((flight) {
        return FlightWithStats(
          flight: flight.readTable(_database.flights),
          dataPoints: [],
          aircraftWithStats: flight.readTableOrNull(
            _database.aircraftWithStatss,
          ),
          departure: flight.readTableOrNull(departure),
          arrival: flight.readTableOrNull(arrival),
        );
      }).toList();
    });
  }

  // Mutating operations (non-reactive)
  Future<int> startSession({
    required String title,
    int? aircraftId,
    int? departureId,
    int? arrivalId,
  }) async {
    final now = DateTime.now();
    return _database
        .into(_database.flights)
        .insert(
          FlightsCompanion.insert(
            title: title,
            departure: Value(departureId),
            arrival: Value(arrivalId),
            departureTime: now,
            arrivalTime: Value(now),
            isRecording: true,
            aircraftId: Value(aircraftId),
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

  Future<void> endSession(int flightId) async {
    final now = DateTime.now();
    await (_database.update(
      _database.flights,
    )..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(
        isRecording: const Value(false),
        arrivalTime: Value(now),
      ),
    );
    await _database.updateNightTime(flightId);
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

  Future<void> setFlightAircraft(int flightId, int? aircraftId) async {
    await (_database.update(_database.flights)
          ..where((f) => f.id.equals(flightId)))
        .write(FlightsCompanion(aircraftId: Value(aircraftId)));
  }

  Future<void> deleteSession(int sessionId) async {
    await (_database.delete(
      _database.flightDataPoints,
    )..where((p) => p.flight.equals(sessionId))).go();
    await (_database.delete(
      _database.flightCrew,
    )..where((c) => c.flight.equals(sessionId))).go();
    await (_database.delete(
      _database.flights,
    )..where((f) => f.id.equals(sessionId))).go();
  }

  Future<void> addFlight({
    required int? departureId,
    required int? arrivalId,
    required String title,
    required DateTime departureTime,
    DateTime? arrivalTime,
    int? aircraftId,
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    String? flightRules,
    String? remarks,
    String? departureIanaLocation,
    String? arrivalIanaLocation,
  }) async {
    await _database
        .into(_database.flights)
        .insert(
          FlightsCompanion.insert(
            title: title,
            departure: Value(departureId),
            arrival: Value(arrivalId),
            departureTime: departureTime,
            arrivalTime: Value(arrivalTime),
            departureIanaLocation: Value(departureIanaLocation),
            arrivalIanaLocation: Value(arrivalIanaLocation),
            isRecording: false,
            aircraftId: Value(aircraftId),
            approachType: Value(approachType),
            nightLandings: Value(nightLandings),
            dayLandings: Value(dayLandings),
            flightRules: Value(flightRules),
            remarks: Value(remarks),
          ),
        );
  }

  Future<void> updateFlight({
    required int flightId,
    required int? departureId,
    required int? arrivalId,
    required String title,
    required DateTime departureTime,
    DateTime? arrivalTime,
    int? aircraftId,
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    String? flightRules,
    String? remarks,
    String? departureIanaLocation,
    String? arrivalIanaLocation,
    bool isRecording = false,
  }) async {
    // write(), not replace(): the columns not listed here (pilot role, where
    // the track comes from) keep their values.
    await (_database.update(
      _database.flights,
    )..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(
        title: Value(title),
        departure: Value(departureId),
        arrival: Value(arrivalId),
        departureTime: Value(departureTime),
        arrivalTime: Value(arrivalTime),
        departureIanaLocation: Value(departureIanaLocation),
        arrivalIanaLocation: Value(arrivalIanaLocation),
        aircraftId: Value(aircraftId),
        approachType: Value(approachType),
        nightLandings: Value(nightLandings),
        dayLandings: Value(dayLandings),
        flightRules: Value(flightRules),
        remarks: Value(remarks),
        isRecording: Value(isRecording),
      ),
    );
  }
}

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FlightRepository(db);
});
