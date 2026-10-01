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
    return _database
        .select(_database.aircrafts)
        .join([
          innerJoin(
            _database.icaoAircrafts,
            _database.icaoAircrafts.id.equalsExp(
              _database.aircrafts.icaoAircraft,
            ),
          ),
        ])
        .watch()
        .asyncMap((rows) async {
          final result = <AircraftWithStats>[];
          for (final row in rows) {
            final aircraft = row.readTable(_database.aircrafts);
            final icao = row.readTable(_database.icaoAircrafts);
            final aircraftWithIcao = AircraftWithIcao(
              aircraft: aircraft,
              icaoAircraft: icao,
            );

            final flightQuery = _database.select(_database.flights)
              ..where((f) => f.aircraftId.equals(aircraft.id))
              ..where((f) => f.isRecording.equals(false));
            final flightRows = await flightQuery.get();
            Duration? totalTime;
            for (final f in flightRows) {
              if (f.arrivalTime != null) {
                final dur = f.arrivalTime!.difference(f.departureTime);
                totalTime = (totalTime ?? Duration.zero) + dur;
              }
            }
            result.add(
              AircraftWithStats(
                aircraft: aircraftWithIcao.aircraft,
                icaoAircraft: aircraftWithIcao.icaoAircraft,
                flightCount: flightRows.length,
                totalFlightTime: totalTime,
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
    return watchAircraftWithIcao(id).asyncMap((aircraftWithIcao) async {
      if (aircraftWithIcao == null) {
        return null;
      }
      final flightQuery = _database.select(_database.flights)
        ..where((f) => f.aircraftId.equals(aircraftWithIcao.aircraft.id))
        ..where((f) => f.isRecording.equals(false));
      final flightRows = await flightQuery.get();
      Duration? totalTime;
      for (final f in flightRows) {
        if (f.arrivalTime != null) {
          final dur = f.arrivalTime!.difference(f.departureTime);
          totalTime = (totalTime ?? Duration.zero) + dur;
        }
      }
      return AircraftWithStats(
        aircraft: aircraftWithIcao.aircraft,
        icaoAircraft: aircraftWithIcao.icaoAircraft,
        flightCount: flightRows.length,
        totalFlightTime: totalTime,
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
        notes: notes != null ? Value(notes) : const Value.absent(),
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
