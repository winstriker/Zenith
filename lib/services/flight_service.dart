import 'dart:async';
import 'dart:collection';
import 'package:drift/drift.dart';
import 'database.dart';

class FlightService {
  final LogbookDatabase database;
  final List<FlightWithStats> _sessions = [];
  int? _activeSessionId;
  final List<Function> callbacks = [];
  bool _initialized = false;

  Future<Airport?> resolveAirport(int? id) async {
    if (id == null) return null;
    final match = await (database.select(
      database.airports,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return match;
  }

  Future<AircraftWithIcao?> resolveAircraft(int? id) async {
    if (id == null) return null;
    final query = database.select(database.aircrafts).join([
      innerJoin(database.icaoAircrafts, database.icaoAircrafts.id.equalsExp(database.aircrafts.icaoAircraft)),
    ])..where(database.aircrafts.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final aircraft = row.readTable(database.aircrafts);
    final icao = row.readTable(database.icaoAircrafts);
    return AircraftWithIcao(aircraft: aircraft, icaoAircraft: icao);
  }

  FlightService(this.database) {
    _loadSessions();
  }

  void addListener(Function fun) {
    callbacks.add(fun);
  }

  void removeListener(Function fun) {
    callbacks.remove(fun);
  }

  void _notify() {
    for (var fun in callbacks) {
      fun();
    }
  }

  bool get isInitialized => _initialized;

  Future<List<FlightWithStats>> getRecentFlights({int limit = 20}) async {
    return database.getRecentFlights(limit: limit);
  }

  Future<void> _loadSessions() async {
    _sessions.clear();

    final flightRows = await database.select(database.flights).get();

    final aircraftCache = <int, AircraftWithIcao?>{};
    Future<AircraftWithIcao?> resolveAircraft(int? id) async {
      if (id == null) return null;
      if (aircraftCache.containsKey(id)) return aircraftCache[id];
      final query = database.select(database.aircrafts).join([
        innerJoin(database.icaoAircrafts, database.icaoAircrafts.id.equalsExp(database.aircrafts.icaoAircraft)),
      ])..where(database.aircrafts.id.equals(id));
      final row = await query.getSingleOrNull();
      if (row == null) return null;
      final aircraft = row.readTable(database.aircrafts);
      final icao = row.readTable(database.icaoAircrafts);
      final result = AircraftWithIcao(aircraft: aircraft, icaoAircraft: icao);
      aircraftCache[id] = result;
      return result;
    }

    for (final row in flightRows) {
      final pointsRows =
          await (database.select(database.flightDataPoints)
                ..where((p) => p.flight.equals(row.id))
                ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
              .get();

      final departure = await resolveAirport(row.departure);
      final arrival = await resolveAirport(row.arrival);
      final aircraft = await resolveAircraft(row.aircraftId);

      _sessions.add(
        FlightWithStats(
          flight: row,
          dataPoints: pointsRows,
          aircraft: aircraft,
          departure: departure,
          arrival: arrival,
        ),
      );
    }

    final active = _sessions.where((s) => s.flight.isRecording).toList();
    if (active.isNotEmpty) {
      _activeSessionId = active.first.flight.id;
    }
    _initialized = true;
    _notify();
  }

  Future<int?> _findAirportId(String? input) async {
    if (input == null || input.trim().isEmpty) return null;
    final term = input.trim();
    final query = database.select(database.airports)
      ..where(
        (a) =>
            a.ident.equals(term) |
            a.icaoCode.equals(term) |
            a.iataCode.equals(term) |
            a.name.equals(term),
      )
      ..limit(1);
    final match = await query.getSingleOrNull();
    if (match != null) {
      return match.id;
    }

    final queryLike = database.select(database.airports)
      ..where(
        (a) =>
            a.ident.like('%$term%') |
            a.icaoCode.like('%$term%') |
            a.iataCode.like('%$term%') |
            a.name.like('%$term%'),
      )
      ..limit(1);
    final matchLike = await queryLike.getSingleOrNull();
    return matchLike?.id;
  }

  UnmodifiableListView<FlightWithStats> get sessions =>
      UnmodifiableListView(_sessions);

  List<FlightWithStats> get recordedSessions =>
      _sessions.where((s) => !s.flight.isRecording).toList()..sort(
        (a, b) => b.flight.departureTime.compareTo(a.flight.departureTime),
      );

  FlightWithStats? get activeSession {
    if (_activeSessionId == null) return null;
    try {
      return _sessions.firstWhere((s) => s.flight.id == _activeSessionId);
    } catch (_) {
      return null;
    }
  }

  FlightWithStats? getSession(int sessionId) {
    try {
      return _sessions.firstWhere((s) => s.flight.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  Future<int> startSession({
    String title = 'New Flight',
    int? aircraftId,
    AircraftWithIcao? aircraft,
    String? departure,
    String? arrival,
  }) async {
    final departureId = await _findAirportId(departure);
    final arrivalId = await _findAirportId(arrival);
    final now = DateTime.now();

    final flightId = await database
        .into(database.flights)
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

    final flight = Flight(
      id: flightId,
      title: title,
      departure: departureId,
      arrival: arrivalId,
      departureTime: now,
      arrivalTime: now,
      isRecording: true,
      aircraftId: aircraftId,
    );

    final session = FlightWithStats(
      flight: flight,
      dataPoints: [],
      aircraft: aircraft,
      departure: await resolveAirport(departureId),
      arrival: await resolveAirport(arrivalId),
    );
    _sessions.add(session);
    _activeSessionId = flightId;
    _notify();
    return flightId;
  }

  void addPoint(
    double latitude,
    double longitude,
    double altitude, {
    double? speed,
    double? heading,
  }) {
    if (_activeSessionId == null) return;
    final index = _sessions.indexWhere((s) => s.flight.id == _activeSessionId);
    if (index == -1) return;

    final flightId = _activeSessionId!;
    final timestamp = DateTime.now();

    final point = FlightDataPoint(
      id: 0,
      flight: flightId,
      longitude: longitude,
      latitude: latitude,
      altitude: altitude.round(),
      timestamp: timestamp,
      speed: speed,
      heading: heading,
    );

    final session = _sessions[index];
    _sessions[index] = session.copyWith(
      dataPoints: [...session.dataPoints, point],
    );

    _insertPoint(
      flightId,
      latitude,
      longitude,
      altitude,
      timestamp,
      speed,
      heading,
    );
    _notify();
  }

  Future<void> _insertPoint(
    int flightId,
    double latitude,
    double longitude,
    double altitude,
    DateTime timestamp,
    double? speed,
    double? heading,
  ) async {
    try {
      await database
          .into(database.flightDataPoints)
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
    } catch (_) {
      // Ignored
    }
  }

  Future<void> endSession() async {
    if (_activeSessionId == null) return;
    final index = _sessions.indexWhere((s) => s.flight.id == _activeSessionId);
    if (index == -1) return;

    final flightId = _activeSessionId!;
    final now = DateTime.now();

    final updated = _sessions[index].copyWith(
      flight: _sessions[index].flight.copyWith(
        isRecording: false,
        arrivalTime: Value(now),
      ),
    );
    _sessions[index] = updated;

    await (database.update(
      database.flights,
    )..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(
        isRecording: const Value(false),
        arrivalTime: Value(now),
      ),
    );

    _activeSessionId = null;
    _notify();
  }

  Future<void> setFlightAircraft(
    int flightId, {
    int? aircraftId,
    AircraftWithIcao? aircraft,
  }) async {
    final index = _sessions.indexWhere((s) => s.flight.id == flightId);
    if (index != -1) {
      final session = _sessions[index];
      _sessions[index] = session.copyWith(
        flight: session.flight.copyWith(aircraftId: Value(aircraftId)),
        aircraft: aircraft,
        removeAircraft: aircraft == null,
      );
    }
    await database.updateFlightAircraft(flightId, aircraftId: aircraftId);
    _notify();
  }

  Future<void> deleteSession(int sessionId) async {
    _sessions.removeWhere((s) => s.flight.id == sessionId);

    await (database.delete(
      database.flightDataPoints,
    )..where((p) => p.flight.equals(sessionId))).go();
    await (database.delete(
      database.flights,
    )..where((f) => f.id.equals(sessionId))).go();
    _notify();
  }

  List<FlightWithStats> searchByDate(DateTime date) {
    return _sessions
        .where(
          (s) =>
              s.flight.departureTime.year == date.year &&
              s.flight.departureTime.month == date.month &&
              s.flight.departureTime.day == date.day &&
              !s.flight.isRecording,
        )
        .toList()
      ..sort(
        (a, b) => b.flight.departureTime.compareTo(a.flight.departureTime),
      );
  }

  List<FlightWithStats> searchByDateRange(DateTime start, DateTime end) {
    return _sessions
        .where(
          (s) =>
              s.flight.departureTime.isAfter(start) &&
              s.flight.departureTime.isBefore(
                end.add(const Duration(days: 1)),
              ) &&
              !s.flight.isRecording,
        )
        .toList()
      ..sort(
        (a, b) => b.flight.departureTime.compareTo(a.flight.departureTime),
      );
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
    final flightId = await database
        .into(database.flights)
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

    _sessions.add(
      FlightWithStats(
        flight: Flight(
          id: flightId,
          title: title,
          departure: departureId,
          arrival: arrivalId,
          departureTime: departureTime,
          arrivalTime: arrivalTime,
          departureIanaLocation: departureIanaLocation,
          arrivalIanaLocation: arrivalIanaLocation,
          isRecording: false,
          aircraftId: aircraftId,
          approachType: approachType,
          nightLandings: nightLandings,
          dayLandings: dayLandings,
          flightRules: flightRules,
          remarks: remarks,
        ),
        dataPoints: [],
        departure: await resolveAirport(departureId),
        arrival: await resolveAirport(arrivalId),
      ),
    );
    _notify();
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
    await database
        .update(database.flights)
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

    // Update local state
    final index = _sessions.indexWhere((f) => f.flight.id == flightId);
    if (index != -1) {
      _sessions[index] = FlightWithStats(
        flight: Flight(
          id: flightId,
          title: title,
          departure: departureId,
          arrival: arrivalId,
          departureTime: departureTime,
          arrivalTime: arrivalTime,
          departureIanaLocation: departureIanaLocation,
          arrivalIanaLocation: arrivalIanaLocation,
          isRecording: false,
          aircraftId: aircraftId,
          approachType: approachType,
          nightLandings: nightLandings,
          dayLandings: dayLandings,
          flightRules: flightRules,
          remarks: remarks,
        ),
        dataPoints: _sessions[index].dataPoints,
        departure: await resolveAirport(departureId),
        arrival: await resolveAirport(arrivalId),
      );
    }
    _notify();
  }
}
