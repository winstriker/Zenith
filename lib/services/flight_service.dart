import 'dart:async';
import 'dart:collection';
import 'package:drift/drift.dart';
import 'database.dart';
import 'person_photo_store.dart';

class FlightService {
  FlightService(this.database, [this._signatures]);
  final LogbookDatabase database;

  /// Where flight signatures live. A signature's file is deleted along with
  /// its flight or when it is replaced.
  final SignatureStore? _signatures;
  final List<FlightWithStats> _sessions = [];
  int? _activeSessionId;
  final List<Function> callbacks = [];

  Future<Airport?> resolveAirport(int? id) async {
    if (id == null) return null;
    final match = await (database.select(
      database.airports,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return match;
  }

  Future<AircraftWithIcao?> resolveAircraft(int? id) async {
    if (id == null) return null;
    final query = database.aircraftWithIcaos.select()
      ..where((tbl) => tbl.id.equals(id))
      ..limit(1);
    return await query.getSingleOrNull();
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

  Future<void> setFlightAircraft(
    int flightId, {
    int? aircraftId,
    AircraftWithStats? aircraft,
  }) async {
    final index = _sessions.indexWhere((s) => s.flight.id == flightId);
    if (index != -1) {
      final session = _sessions[index];
      _sessions[index] = session.copyWith(
        flight: session.flight.copyWith(aircraftId: Value(aircraftId)),
        aircraftWithStats: aircraft,
        removeAircraft: aircraft == null,
      );
    }
    await database.updateFlightAircraft(flightId, aircraftId: aircraftId);
    _notify();
  }

  Future<void> deleteSession(int sessionId) async {
    _sessions.removeWhere((s) => s.flight.id == sessionId);
    final signature = await _signatureOf(sessionId);

    await (database.delete(
      database.flightDataPoints,
    )..where((p) => p.flight.equals(sessionId))).go();
    await (database.delete(
      database.flightCrew,
    )..where((c) => c.flight.equals(sessionId))).go();
    await (database.delete(
      database.flights,
    )..where((f) => f.id.equals(sessionId))).go();
    await _signatures?.delete(signature);
    _notify();
  }

  Future<String?> _signatureOf(int flightId) async {
    final query = database.selectOnly(database.flights)
      ..addColumns([database.flights.signatureFile])
      ..where(database.flights.id.equals(flightId));
    final row = await query.getSingleOrNull();
    return row?.read(database.flights.signatureFile);
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

  /// Returns the id of the new flight.
  Future<int> addFlight({
    required int? departureId,
    required int? arrivalId,
    required String title,
    required DateTime departureTime,
    DateTime? arrivalTime,
    int? aircraftId,
    int? simulatorId,
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    String? flightRules,
    String? remarks,
    String? departureIanaLocation,
    String? arrivalIanaLocation,
    String? pilotRole,
    int? instrumentMinutes,
    int? nightMinutes,
    bool proficiencyCheck = false,
    String? signatureFile,
    List<CrewMember> crew = const [],
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
            simulatorId: Value(simulatorId),
            approachType: Value(approachType),
            nightLandings: Value(nightLandings),
            dayLandings: Value(dayLandings),
            flightRules: Value(flightRules),
            remarks: Value(remarks),
            pilotRole: Value(pilotRole),
            instrumentMinutes: Value(instrumentMinutes),
            nightMinutes: Value(nightMinutes),
            proficiencyCheck: Value(proficiencyCheck),
            signatureFile: Value(signatureFile),
          ),
        );

    await database.setFlightCrew(flightId, crew);

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
          simulatorId: simulatorId,
          approachType: approachType,
          nightLandings: nightLandings,
          dayLandings: dayLandings,
          flightRules: flightRules,
          remarks: remarks,
          pilotRole: pilotRole,
          instrumentMinutes: instrumentMinutes,
          nightMinutes: nightMinutes,
          proficiencyCheck: proficiencyCheck,
          signatureFile: signatureFile,
        ),
        dataPoints: [],
        departure: await resolveAirport(departureId),
        arrival: await resolveAirport(arrivalId),
      ),
    );
    _notify();
    return flightId;
  }

  Future<void> updateFlight({
    required int flightId,
    required int? departureId,
    required int? arrivalId,
    required String title,
    required DateTime departureTime,
    DateTime? arrivalTime,
    int? aircraftId,
    int? simulatorId,
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    String? flightRules,
    String? remarks,
    String? departureIanaLocation,
    String? arrivalIanaLocation,
    String? pilotRole,
    int? instrumentMinutes,
    int? nightMinutes,
    bool proficiencyCheck = false,
    List<CrewMember> crew = const [],
    bool isRecording = false,

    /// The stored signature file, or null to remove it. Absent leaves the
    /// signature as it is.
    Value<String?> signatureFile = const Value.absent(),
  }) async {
    final oldSignature = signatureFile.present
        ? await _signatureOf(flightId)
        : null;
    // write(), not replace(): editing a flight must not wipe the columns the
    // form knows nothing of (where its track comes from, logbook overrides).
    await (database.update(
      database.flights,
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
        simulatorId: Value(simulatorId),
        approachType: Value(approachType),
        nightLandings: Value(nightLandings),
        dayLandings: Value(dayLandings),
        flightRules: Value(flightRules),
        remarks: Value(remarks),
        pilotRole: Value(pilotRole),
        instrumentMinutes: Value(instrumentMinutes),
        nightMinutes: Value(nightMinutes),
        proficiencyCheck: Value(proficiencyCheck),
        isRecording: Value(isRecording),
        signatureFile: signatureFile,
      ),
    );
    if (signatureFile.present && oldSignature != signatureFile.value) {
      await _signatures?.delete(oldSignature);
    }

    await database.setFlightCrew(flightId, crew);

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
          simulatorId: simulatorId,
          approachType: approachType,
          nightLandings: nightLandings,
          dayLandings: dayLandings,
          flightRules: flightRules,
          remarks: remarks,
          pilotRole: pilotRole,
          instrumentMinutes: instrumentMinutes,
          nightMinutes: nightMinutes,
          proficiencyCheck: proficiencyCheck,
          trackSource: _sessions[index].flight.trackSource,
          logbookOverrides: _sessions[index].flight.logbookOverrides,
          signatureFile: signatureFile.present
              ? signatureFile.value
              : _sessions[index].flight.signatureFile,
        ),
        dataPoints: _sessions[index].dataPoints,
        departure: await resolveAirport(departureId),
        arrival: await resolveAirport(arrivalId),
      );
    }
    _notify();
  }
}
