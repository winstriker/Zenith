import 'package:drift/drift.dart';

import 'database.dart';
import 'person_photo_store.dart';

/// Saves and deletes flights along with their crew and signature.
class FlightService {
  FlightService(this.database, [this._signatures]);
  final LogbookDatabase database;

  /// Where flight signatures live. A signature's file is deleted along with
  /// its flight or when it is replaced.
  final SignatureStore? _signatures;

  Future<void> deleteSession(int sessionId) => deleteSessions([sessionId]);

  /// Deletes the flights in one transaction, then their signature files.
  Future<void> deleteSessions(Iterable<int> sessionIds) async {
    final signatures = await database.transaction(() async {
      final signatures = <String?>[];
      for (final id in sessionIds) {
        signatures.add(await _signatureOf(id));
        await database.deleteFlight(id);
      }
      return signatures;
    });
    for (final signature in signatures) {
      await _signatures?.delete(signature);
    }
  }

  Future<String?> _signatureOf(int flightId) async {
    final query = database.selectOnly(database.flights)
      ..addColumns([database.flights.signatureFile])
      ..where(database.flights.id.equals(flightId));
    final row = await query.getSingleOrNull();
    return row?.read(database.flights.signatureFile);
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
    int? mountainLandings,
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
    return database.transaction(() async {
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
              mountainLandings: Value(mountainLandings),
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
      return flightId;
    });
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
    int? mountainLandings,
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
    final oldSignature = await database.transaction(() async {
      final old = signatureFile.present ? await _signatureOf(flightId) : null;
      // write(), not replace(): editing a flight must not wipe the columns
      // the form knows nothing of (where its track comes from, logbook
      // overrides).
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
          mountainLandings: Value(mountainLandings),
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
      await database.setFlightCrew(flightId, crew);
      return old;
    });
    if (signatureFile.present && oldSignature != signatureFile.value) {
      await _signatures?.delete(oldSignature);
    }
  }
}
