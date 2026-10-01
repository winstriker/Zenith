import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../services/database.dart';

/// Repository for aircraft data access using Drift's reactive queries
class AircraftRepository {
  AircraftRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of all aircraft with stats (joined with ICAO data)
  Stream<List<AircraftWithStats>> watchAircraftsWithStats() {
    return _database.select(_database.aircraftsStats).watch().asyncMap((
      rows,
    ) async {
      final result = <AircraftWithStats>[];
      for (final row in rows) {
        result.add(
          AircraftWithStats(
            aircraft: Aircraft(
              id: row.id,
              icaoAircraft: row.icaoAircraft,
              tailNumber: row.tailNumber,
            ),
            nightLandings: row.nightLandings ?? 0,
            dayLandings: row.dayLandings ?? 0,
            icaoAircraft: IcaoAircraft(
              id: row.icaoAircraft,
              modelFullName: row.modelFullName,
              designator: row.designator,
              wakeTurbolenceCategory: row.wakeTurbolenceCategory,
              wakeTurbolenceGroup: row.wakeTurbolenceGroup,
              manufacturer: row.manufacturer,
              description: row.description,
              engineCount: row.engineCount,
              engineType: row.engineType,
              userInserted: row.userInserted,
            ),
            flightCount: row.flightCount ?? 0,
            totalFlightTime: Duration(minutes: row.totalFlightTime ?? 0),
          ),
        );
      }
      return result;
    });
  }

  /// Stream of a single aircraft with ICAO data
  Stream<AircraftWithIcao?> watchAircraftWithIcao(int id) {
    return (_database.select(_database.aircrafts)
          ..where((a) => a.id.equals(id)))
        .join([
          innerJoin(
            _database.icaoAircrafts,
            _database.icaoAircrafts.id.equalsExp(
              _database.aircrafts.icaoAircraft,
            ),
          ),
        ])
        .watchSingleOrNull()
        .map((row) {
          if (row == null) return null;
          final aircraft = row.readTable(_database.aircrafts);
          final icao = row.readTable(_database.icaoAircrafts);
          return AircraftWithIcao(aircraft: aircraft, icaoAircraft: icao);
        });
  }

  /// Stream of a specific aircraft
  Stream<Aircraft?> watchAircraft(int id) {
    return (_database.select(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  Stream<AircraftWithStats?> watchAircraftWithStats(int id) {
    final stmt = _database.aircraftsStats.select();
    stmt.where((acws) => acws.id.equals(id));
    stmt.limit(1);
    return stmt.watchSingle().asyncMap((acs) async {
      return AircraftWithStats(
        aircraft: Aircraft(
          id: acs.id,
          icaoAircraft: acs.icaoAircraft,
          tailNumber: acs.tailNumber,
        ),
        icaoAircraft: IcaoAircraft(
          id: acs.icaoAircraft,
          modelFullName: acs.modelFullName,
          designator: acs.designator,
          wakeTurbolenceCategory: acs.wakeTurbolenceCategory,
          wakeTurbolenceGroup: acs.wakeTurbolenceGroup,
          manufacturer: acs.manufacturer,
          description: acs.description,
          engineCount: acs.engineCount,
          engineType: acs.engineType,
          userInserted: acs.userInserted,
        ),
        dayLandings: acs.dayLandings ?? 0,
        nightLandings: acs.nightLandings ?? 0,
        flightCount: acs.flightCount ?? 0,
        totalFlightTime: Duration(minutes: acs.totalFlightTime ?? 0),
      );
    });
  }

  /// Search ICAO aircrafts by model name, manufacturer, or type
  Future<List<IcaoAircraft>> searchIcaoAircrafts(
    String query, {
    int limit = 50,
  }) async {
    return _database.searchIcaoAircrafts(query, limit: limit);
  }

  /// Stream of all ICAO aircrafts
  Stream<List<IcaoAircraft>> watchAllIcaoAircrafts() {
    return (_database.select(
      _database.icaoAircrafts,
    )..orderBy([(a) => OrderingTerm.asc(a.modelFullName)])).watch();
  }

  /// Stream of flights for an aircraft
  Stream<List<FlightWithStats>> watchFlightsForAircraft(
    int aircraftId, {
    int limit = 5,
    int offset = 0,
  }) {
    return (_database.select(_database.flights)
          ..where((f) => f.aircraftId.equals(aircraftId))
          ..orderBy([(f) => OrderingTerm.desc(f.departureTime)])
          ..limit(limit, offset: offset))
        .watch()
        .asyncMap((flightRows) async {
          if (flightRows.isEmpty) return <FlightWithStats>[];

          final flightIds = flightRows.map((f) => f.id).toList();

          final dataPointsQuery = _database.select(_database.flightDataPoints)
            ..where((p) => p.flight.isIn(flightIds))
            ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]);
          final allPoints = await dataPointsQuery.get();

          final pointsByFlight = <int, List<FlightDataPoint>>{};
          for (final point in allPoints) {
            pointsByFlight.putIfAbsent(point.flight, () => []).add(point);
          }

          final aircraftWithIcao = await _database.getAircraftWithIcao(
            aircraftId,
          );

          final results = <FlightWithStats>[];
          for (final flight in flightRows) {
            final points = pointsByFlight[flight.id] ?? const [];
            final departure = flight.departure != null
                ? await (_database.select(_database.airports)
                        ..where((a) => a.id.equals(flight.departure!)))
                      .getSingleOrNull()
                : null;
            final arrival = flight.arrival != null
                ? await (_database.select(_database.airports)
                        ..where((a) => a.id.equals(flight.arrival!)))
                      .getSingleOrNull()
                : null;
            results.add(
              FlightWithStats(
                flight: flight,
                dataPoints: points,
                aircraft: aircraftWithIcao,
                departure: departure,
                arrival: arrival,
              ),
            );
          }
          return results;
        });
  }

  // Mutating operations
  Future<int> addAircraft({
    required int icaoAircraftId,
    required String tailNumber,
    String? notes,
  }) async {
    return _database
        .into(_database.aircrafts)
        .insert(
          AircraftsCompanion.insert(
            icaoAircraft: icaoAircraftId,
            tailNumber: tailNumber,
            notes: Value(notes),
          ),
        );
  }

  Future<int> addIcaoAircraft({
    required String modelFullName,
    required String manufacturer,
    required String designator,
    required WakeTurbolenceCategory wakeTurbolenceCategory,
    required WakeTurbolenceGroup wakeTurbolenceGroup,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) async {
    return _database.addIcaoAircraft(
      modelFullName: modelFullName,
      manufacturer: manufacturer,
      designator: designator,
      wakeTurbolenceCategory: wakeTurbolenceCategory,
      wakeTurbolenceGroup: wakeTurbolenceGroup,
      description: description,
      engineCount: engineCount,
      engineType: engineType,
    );
  }

  Future<void> updateAircraft(
    int id, {
    int? icaoAircraftId,
    String? tailNumber,
    String? notes,
  }) async {
    await (_database.update(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        icaoAircraft: icaoAircraftId != null
            ? Value(icaoAircraftId)
            : const Value.absent(),
        tailNumber: tailNumber != null
            ? Value(tailNumber)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value(null),
      ),
    );
  }

  Future<void> deleteAircraft(int id) async {
    await (_database.update(_database.flights)
          ..where((f) => f.aircraftId.equals(id)))
        .write(const FlightsCompanion(aircraftId: Value(null)));
    await (_database.delete(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).go();
  }
}

final aircraftRepositoryProvider = Provider<AircraftRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AircraftRepository(db);
});
