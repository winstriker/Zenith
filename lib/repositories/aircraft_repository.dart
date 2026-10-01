import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../services/database.dart';

/// Repository for aircraft data access using Drift's reactive queries
class AircraftRepository {
  AircraftRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of all aircraft with stats
  Stream<List<AircraftWithStats>> watchAircraftsWithStats() {
    return _database.select(_database.aircrafts).watch().asyncMap((
      aircraftList,
    ) async {
      final result = <AircraftWithStats>[];
      for (final ac in aircraftList) {
        final flightQuery = _database.select(_database.flights)
          ..where((f) => f.aircraftId.equals(ac.id))
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
            aircraft: ac,
            flightCount: flightRows.length,
            totalFlightTime: totalTime,
          ),
        );
      }
      return result;
    });
  }

  /// Stream of a single aircraft
  Stream<Aircraft?> watchAircraft(int id) {
    return (_database.select(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  Stream<AircraftWithStats?> watchAircraftWithStats(int id) {
    return (_database.select(_database.aircrafts)
          ..where((a) => a.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((aircraft) async {
          if (aircraft == null) {
            return null;
          }
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
          return AircraftWithStats(
            aircraft: aircraft,
            flightCount: flightRows.length,
            totalFlightTime: totalTime,
          );
        });
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

          final aircraft = await (_database.select(
            _database.aircrafts,
          )..where((a) => a.id.equals(aircraftId))).getSingleOrNull();

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
                aircraft: aircraft,
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
    required String type,
    required String model,
    required String tailNumber,
    required String manufacturer,
    String? notes,
  }) async {
    return _database
        .into(_database.aircrafts)
        .insert(
          AircraftsCompanion.insert(
            type: type,
            model: model,
            tailNumber: tailNumber,
            manufacturer: manufacturer,
            notes: Value(notes),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateAircraft(
    int id, {
    String? type,
    String? model,
    String? tailNumber,
    String? notes,
  }) async {
    await (_database.update(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        type: type != null ? Value(type) : const Value.absent(),
        model: model != null ? Value(model) : const Value.absent(),
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
