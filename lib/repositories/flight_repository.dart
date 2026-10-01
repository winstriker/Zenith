import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../services/database.dart';

/// Repository for flight data access using Drift's reactive queries
class FlightRepository {
  FlightRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of all recorded flights with stats, ordered by departure time descending
  Stream<List<FlightWithStats>> watchRecordedFlights({int limit = 100}) {
    return _watchFlights(
      where: (f) => f.isRecording.equals(false),
      limit: limit,
    );
  }

  /// Stream of active recording session
  Stream<FlightWithStats?> watchActiveFlight() {
    return _watchFlights(
      where: (f) => f.isRecording.equals(true),
      limit: 1,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  /// Stream of a specific flight by ID
  Stream<FlightWithStats?> watchFlightById(int flightId) {
    return _watchFlights(
      where: (f) => f.id.equals(flightId),
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
      where: (f) => f.aircraftId.equals(aircraftId),
      limit: limit,
      offset: offset,
    );
  }

  /// Returns the total minutes flown as an [int]
  //TODO: ADD A VIEW ON flight_time instead of selecting everything every time
  Stream<int> watchTotalFlightTime() {
    return _database
        .customSelect(
          "SELECT SUM(flight_time) AS total_flight_time FROM(SELECT (arrival_time - departure_time) AS flight_time FROM flights)",
          readsFrom: {_database.flights},
        )
        .watch()
        .map((row) {
          return (row.first.read<int>('total_flight_time') / 60).toInt();
        });
  }

  /// Stream of recent flights (for home page)
  Stream<List<FlightWithStats>> watchRecentFlights({int limit = 20}) {
    return watchRecordedFlights(limit: limit);
  }

  /// Internal method to watch flights with joins for related data
  Stream<List<FlightWithStats>> _watchFlights({
    required Expression<bool> Function(Flights) where,
    int? limit,
    int? offset,
  }) {
    // First, get the base flight stream
    final flightStream =
        (_database.select(_database.flights)
              ..where(where)
              ..orderBy([(f) => OrderingTerm.desc(f.departureTime)]))
            .watch();

    // Transform the flight stream to include related data
    return flightStream.asyncMap((flightRows) async {
      final flightsToProcess = limit != null
          ? flightRows.take(limit).toList()
          : flightRows;
      if (offset != null && offset > 0) {
        flightsToProcess.removeRange(
          0,
          offset.clamp(0, flightsToProcess.length),
        );
      }

      if (flightsToProcess.isEmpty) return <FlightWithStats>[];

      final flightIds = flightsToProcess.map((f) => f.id).toList();

      // Fetch all data points for these flights in one query
      final dataPointsRows =
          await (_database.select(_database.flightDataPoints)
                ..where((p) => p.flight.isIn(flightIds))
                ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
              .get();

      final pointsByFlight = <int, List<FlightDataPoint>>{};
      for (final point in dataPointsRows) {
        pointsByFlight.putIfAbsent(point.flight, () => []).add(point);
      }

      // Fetch all airports for these flights
      final airportIds = <int>{};
      for (final f in flightsToProcess) {
        if (f.departure != null) airportIds.add(f.departure!);
        if (f.arrival != null) airportIds.add(f.arrival!);
      }

      final airportsMap = <int, Airport>{};
      if (airportIds.isNotEmpty) {
        final airportsRows = await (_database.select(
          _database.airports,
        )..where((a) => a.id.isIn(airportIds.toList()))).get();
        for (final a in airportsRows) {
          airportsMap[a.id] = a;
        }
      }

      // Fetch all aircraft for these flights (with ICAO data)
      final aircraftIds = flightsToProcess
          .where((f) => f.aircraftId != null)
          .map((f) => f.aircraftId!)
          .toSet();

      final aircraftMap = <int, AircraftWithIcao>{};
      if (aircraftIds.isNotEmpty) {
        // Join aircrafts with icaoAircrafts
        final aircraftRows = await (_database.select(_database.aircrafts).join([
          innerJoin(
            _database.icaoAircrafts,
            _database.icaoAircrafts.id.equalsExp(
              _database.aircrafts.icaoAircraft,
            ),
          ),
        ])..where(_database.aircrafts.id.isIn(aircraftIds.toList()))).get();

        for (final row in aircraftRows) {
          final aircraft = row.readTable(_database.aircrafts);
          final icao = row.readTable(_database.icaoAircrafts);
          aircraftMap[aircraft.id] = AircraftWithIcao(
            aircraft: aircraft,
            icaoAircraft: icao,
          );
        }
      }

      // Build FlightWithStats objects
      return flightsToProcess.map((flight) {
        return FlightWithStats(
          flight: flight,
          dataPoints: pointsByFlight[flight.id] ?? const [],
          aircraft: flight.aircraftId != null
              ? aircraftMap[flight.aircraftId!]
              : null,
          departure: flight.departure != null
              ? airportsMap[flight.departure!]
              : null,
          arrival: flight.arrival != null ? airportsMap[flight.arrival!] : null,
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
    await _database
        .update(_database.flights)
        .replace(
          FlightsCompanion(
            id: Value(flightId),
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
