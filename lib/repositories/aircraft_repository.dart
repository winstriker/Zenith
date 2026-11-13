import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../services/database.dart';

/// Repository for aircraft data access using Drift's reactive queries
class AircraftRepository {
  AircraftRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of a specific aircraft with stats
  Stream<AircraftWithStats?> watchAircraftWithStats(int id) {
    final stmt = _database.aircraftWithStatss.select();
    stmt.where((acws) => acws.id.equals(id));
    stmt.limit(1);
    return stmt.watchSingle();
  }

  /// Stream of all aircraft with stats
  Stream<List<AircraftWithStats>> watchAircraftsWithStats() {
    return _database.select(_database.aircraftWithStatss).watch();
  }

  /// Stream of a single aircraft with ICAO data
  Stream<AircraftWithIcao?> watchAircraftWithIcao(int id) {
    return (_database.select(
      _database.aircraftWithIcaos,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Stream of a specific aircraft
  Stream<Aircraft?> watchAircraft(int id) {
    return (_database.select(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Search ICAO aircrafts by model name, manufacturer, or type
  Future<List<IcaoAircraft>> searchIcaoAircrafts(
    String query, {
    int limit = 50,
  }) async {
    final term = '%$query%';
    return (_database.select(_database.icaoAircrafts)
          ..where(
            (a) =>
                a.modelFullName.like(term) |
                a.manufacturer.like(term) |
                a.designator.like(term),
          )
          ..orderBy([
            (a) => OrderingTerm.asc(a.manufacturer),
            (a) => OrderingTerm.asc(a.modelFullName),
          ])
          ..limit(limit))
        .get();
  }

  /// Stream of all ICAO aircrafts
  Stream<List<IcaoAircraft>> watchAllIcaoAircrafts() {
    return (_database.select(_database.icaoAircrafts)..orderBy([
          (a) => OrderingTerm.asc(a.manufacturer),
          (a) => OrderingTerm.asc(a.modelFullName),
        ]))
        .watch();
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
    required WakeTurbulenceCategory wakeTurbolenceCategory,
    required WakeTurbulenceGroup wakeTurbolenceGroup,
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

  /// Deletes an aircraft and detaches it from its flights, atomically.
  Future<void> deleteAircraft(int id) {
    return _database.transaction(() async {
      await (_database.update(_database.flights)
            ..where((f) => f.aircraftId.equals(id)))
          .write(const FlightsCompanion(aircraftId: Value(null)));
      await (_database.delete(
        _database.aircrafts,
      )..where((a) => a.id.equals(id))).go();
    });
  }
}

final aircraftRepositoryProvider = Provider<AircraftRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AircraftRepository(db);
});
