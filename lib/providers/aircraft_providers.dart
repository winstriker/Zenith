import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_progress.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/aircraft_types_service.dart';
import '../services/database.dart';
import 'database_provider.dart';

/// How many aircraft the user has.
final aircraftCountProvider = StreamProvider<int>(
  (ref) => ref.watch(aircraftRepositoryProvider).watchAircraftCount(),
);

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

/// An aircraft with its stats.
final aircraftWithStatsByIdStreamProvider = StreamProvider.autoDispose
    .family<AircraftWithStats?, int>(
      (ref, id) =>
          ref.watch(aircraftRepositoryProvider).watchAircraftWithStats(id),
    );

/// The latest flights flown with an aircraft.
final flightsForAircraftStreamProvider = StreamProvider.autoDispose
    .family<List<FlightWithStats>, int>(
      (ref, id) =>
          ref.watch(flightRepositoryProvider).watchFlightsForAircraft(id),
    );

/// Every ICAO aircraft type, by manufacturer and model.
final icaoAircraftsStreamProvider = StreamProvider<List<IcaoAircraft>>((ref) {
  return ref.watch(aircraftRepositoryProvider).watchAllIcaoAircrafts();
});

/// One ICAO type; null once deleted.
final icaoAircraftProvider = StreamProvider.autoDispose
    .family<IcaoAircraft?, int>((ref, id) {
      return ref.watch(aircraftRepositoryProvider).watchIcaoAircraft(id);
    });

/// The user's aircraft of an ICAO type.
final aircraftsOfTypeProvider = StreamProvider.autoDispose
    .family<List<AircraftWithStats>, int>((ref, icaoAircraftId) {
      return ref
          .watch(aircraftRepositoryProvider)
          .watchAircraftsOfType(icaoAircraftId);
    });

/// Progress of the ICAO types download. Watching it starts the first
/// download, when the table has no types yet.
class AircraftTypesLoadNotifier extends Notifier<SyncProgress> {
  late AircraftTypesService _service;

  @override
  SyncProgress build() {
    _service = ref.watch(aircraftTypesServiceProvider);
    void onChange() {
      state = _service.progress.value;
      // Drift tells streams about writes from the sync isolate too; this
      // makes sure the lists show the new types even if it didn't.
      if (state.phase == SyncPhase.done) {
        ref.invalidate(icaoAircraftsStreamProvider);
      }
    }

    _service.progress.addListener(onChange);
    ref.onDispose(() => _service.progress.removeListener(onChange));
    // Deferred: loadData updates progress synchronously, which must not
    // happen while this provider is building.
    Future.microtask(_service.loadData);
    return _service.progress.value;
  }

  Future<void> refresh() => _service.loadData(forceDownload: true);
}

final aircraftTypesLoadProvider =
    NotifierProvider<AircraftTypesLoadNotifier, SyncProgress>(
      AircraftTypesLoadNotifier.new,
    );

/// AircraftTypesService provider
final aircraftTypesServiceProvider = Provider<AircraftTypesService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = AircraftTypesService(db);
  ref.onDispose(service.dispose);
  return service;
});
