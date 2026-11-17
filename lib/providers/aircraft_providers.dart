import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/aircraft_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/aircraft_types_service.dart';
import '../services/database.dart';
import 'database_provider.dart';

// Aircraft Repository Provider
// Provided by aircraft_repository.dart

/// Stream of all aircraft with stats
final aircraftListStreamProvider = StreamProvider<List<AircraftWithStats>>((
  ref,
) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAircraftsWithStats();
});

/// Which part of the aircraft list a paged list shows.
typedef AircraftPageKey = ({int limit, String query});

/// The first `limit` aircraft matching `query`, in the order they were
/// added. Lists load more by asking a bigger `limit`.
final aircraftPageProvider = StreamProvider.autoDispose
    .family<List<AircraftWithStats>, AircraftPageKey>((ref, key) {
      return ref
          .watch(aircraftRepositoryProvider)
          .watchAircraftsWithStats(limit: key.limit, query: key.query);
    });

/// Stream of a specific aircraft
final aircraftByIdStreamProvider = StreamProvider.family<Aircraft?, int>((
  ref,
  aircraftId,
) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAircraft(aircraftId);
});

/// Stream of a specific aircraft
final aircraftWithStatsByIdStreamProvider =
    StreamProvider.family<AircraftWithStats?, int>((ref, aircraftId) {
      final repository = ref.watch(aircraftRepositoryProvider);
      return repository.watchAircraftWithStats(aircraftId);
    });

/// Stream of flights for a specific aircraft
final flightsForAircraftStreamProvider =
    StreamProvider.family<List<FlightWithStats>, int>((ref, aircraftId) {
      final repository = ref.watch(flightRepositoryProvider);
      return repository.watchFlightsForAircraft(aircraftId);
    });

class AircraftTypesLoadNotifier extends Notifier<int> {
  late final AircraftTypesService _service;

  @override
  int build() {
    _service = ref.watch(aircraftTypesServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    _service.loadData();
    return 0;
  }

  void _onServiceChange() {
    state = state + 1;
  }

  Future<void> refresh() async {
    _onServiceChange();
    await _service.loadData(forceDownload: true);
  }
}

final aircraftTypesLoadProvider =
    NotifierProvider<AircraftTypesLoadNotifier, int>(
      AircraftTypesLoadNotifier.new,
    );

/// AircraftTypesService provider
final aircraftTypesServiceProvider = Provider<AircraftTypesService>((ref) {
  final db = ref.watch(databaseProvider);
  return AircraftTypesService(db);
});
