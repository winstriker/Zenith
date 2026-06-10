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

    final airportCache = <int, String?>{};
    Future<String?> resolveIdent(int? id) async {
      if (id == null) return null;
      if (airportCache.containsKey(id)) return airportCache[id];
      final match = await (database.select(database.airports)
        ..where((a) => a.id.equals(id))).getSingleOrNull();
      final ident = match?.ident ?? match?.icaoCode ?? match?.iataCode ?? match?.name;
      airportCache[id] = ident;
      return ident;
    }

    for (final row in flightRows) {
      final pointsRows =
          await (database.select(database.flightDataPoints)
                ..where((p) => p.flight.equals(row.id))
                ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
              .get();

      final depIdent = await resolveIdent(row.departure);
      final arrIdent = await resolveIdent(row.arrival);

      _sessions.add(FlightWithStats(
        flight: row,
        dataPoints: pointsRows,
        aircraftType: row.aircraftType,
        departureIdent: depIdent,
        arrivalIdent: arrIdent,
      ));
    }

    final active = _sessions
        .where((s) => s.flight.isRecording)
        .toList();
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
      _sessions.where((s) => !s.flight.isRecording).toList()
        ..sort((a, b) => b.flight.departureTime.compareTo(a.flight.departureTime));

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
    String? aircraftType,
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
            aircraftType: Value(aircraftType),
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
      aircraftType: aircraftType,
    );

    final session = FlightWithStats(
      flight: flight,
      dataPoints: [],
      aircraftType: aircraftType,
      departureIdent: departure,
      arrivalIdent: arrival,
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
      ..sort((a, b) => b.flight.departureTime.compareTo(a.flight.departureTime));
  }

  List<FlightWithStats> searchByDateRange(DateTime start, DateTime end) {
    return _sessions
        .where(
          (s) =>
              s.flight.departureTime.isAfter(start) &&
              s.flight.departureTime.isBefore(end.add(const Duration(days: 1))) &&
              !s.flight.isRecording,
        )
        .toList()
      ..sort((a, b) => b.flight.departureTime.compareTo(a.flight.departureTime));
  }
}
