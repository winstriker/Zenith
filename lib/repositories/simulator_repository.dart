import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// The simulators the user flies sessions in.
class SimulatorRepository {
  SimulatorRepository(this._database);
  final LogbookDatabase _database;

  /// The simulators with their type and sessions, in the order they were
  /// added.
  ///
  /// Only those matching [query] (see `sqlMatchesAllTokens`), and only the
  /// first [limit] of them when given: a list grows by asking a bigger one.
  Stream<List<SimulatorWithStats>> watchSimulators({
    int? limit,
    String query = '',
  }) {
    final sims = _database.simulators;
    final type = _database.icaoAircrafts;
    final stmt = _statsQuery()
      ..where(
        sqlMatchesAllTokens(searchTokens(query), [
          sims.typeRating,
          sims.qualificationNumber,
          sims.organisation,
          sims.level,
          sims.kind,
          sims.notes,
          type.designator,
          type.modelFullName,
          type.manufacturer,
        ]),
      )
      ..orderBy([OrderingTerm.asc(sims.id)]);
    if (limit != null) stmt.limit(limit);
    return stmt.watch().map((rows) => rows.map(_toStats).toList());
  }

  /// One simulator with its type and sessions; null once deleted.
  Stream<SimulatorWithStats?> watchSimulator(int id) {
    final stmt = _statsQuery()..where(_database.simulators.id.equals(id));
    return stmt.watch().map(
      (rows) => rows.isEmpty ? null : _toStats(rows.first),
    );
  }

  static const _sessionCount = CustomExpression<int>(
    'COUNT(flights.id)',
    precedence: Precedence.primary,
  );

  static const _sessionMinutes = CustomExpression<int>(
    'COALESCE(SUM(CAST((flights.arrival_time - flights.departure_time) / 60 '
    'AS INTEGER)), 0)',
    precedence: Precedence.primary,
  );

  JoinedSelectStatement<HasResultSet, dynamic> _statsQuery() {
    final sims = _database.simulators;
    final type = _database.icaoAircrafts;
    final flights = _database.flights;
    return _database.select(sims).join([
        leftOuterJoin(type, sims.icaoAircraft.equalsExp(type.id)),
        leftOuterJoin(flights, flights.simulatorId.equalsExp(sims.id)),
      ])
      ..addColumns([_sessionCount, _sessionMinutes])
      ..groupBy([sims.id]);
  }

  SimulatorWithStats _toStats(TypedResult row) => SimulatorWithStats(
    simulator: row.readTable(_database.simulators),
    type: row.readTableOrNull(_database.icaoAircrafts),
    sessionCount: row.read(_sessionCount) ?? 0,
    totalMinutes: row.read(_sessionMinutes) ?? 0,
  );

  Future<int> addSimulator(SimulatorsCompanion simulator) =>
      _database.into(_database.simulators).insert(_clean(simulator));

  /// Rewrites every column of simulator [id] with [simulator].
  Future<void> updateSimulator(int id, SimulatorsCompanion simulator) async {
    await (_database.update(
      _database.simulators,
    )..where((s) => s.id.equals(id))).write(_clean(simulator));
  }

  /// A type rating only means something next to [AircraftClass.type].
  static SimulatorsCompanion _clean(SimulatorsCompanion s) {
    final rating = s.typeRating.present ? s.typeRating.value?.trim() : null;
    final isType = s.aircraftClass.value == AircraftClass.type;
    return s.copyWith(
      typeRating: Value(
        isType && rating != null && rating.isNotEmpty ? rating : null,
      ),
    );
  }

  /// How many sessions were flown in simulator [id].
  Future<int> sessionCount(int id) async {
    final count = _database.flights.id.count();
    final query = _database.selectOnly(_database.flights)
      ..addColumns([count])
      ..where(_database.flights.simulatorId.equals(id));
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Deletes simulator [id]. Refused (returns false) while sessions are
  /// logged in it: unlinked, they would pass for flights.
  Future<bool> deleteSimulator(int id) {
    return _database.transaction(() async {
      if (await sessionCount(id) > 0) return false;
      await (_database.delete(
        _database.simulators,
      )..where((s) => s.id.equals(id))).go();
      return true;
    });
  }
}

final simulatorRepositoryProvider = Provider<SimulatorRepository>(
  (ref) => SimulatorRepository(ref.watch(databaseProvider)),
);

/// Which part of the simulator list a paged list shows.
typedef SimulatorPageKey = ({int limit, String query});

/// The first `limit` simulators matching `query`, in the order they were
/// added. Lists load more by asking a bigger `limit`.
final simulatorPageProvider = StreamProvider.autoDispose
    .family<List<SimulatorWithStats>, SimulatorPageKey>(
      (ref, key) => ref
          .watch(simulatorRepositoryProvider)
          .watchSimulators(limit: key.limit, query: key.query),
    );

final simulatorByIdProvider = StreamProvider.autoDispose
    .family<SimulatorWithStats?, int>(
      (ref, id) => ref.watch(simulatorRepositoryProvider).watchSimulator(id),
    );
