import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/airport_repository.dart';
import '../services/airport_service.dart';
import '../services/database.dart';
import 'database_provider.dart';

// Airport Repository Provider
// Provided by airport_repository.dart

/// Stream of recent airports (from recent flights)
final recentAirportsStreamProvider = StreamProvider<List<Airport>>((ref) {
  // For now, return empty stream - can be enhanced later
  return Stream.value(<Airport>[]);
});

/// Stream of airports matching search criteria
final airportSearchStreamProvider =
    StreamProvider.family<
      List<Airport>,
      ({String query, String? countryCode, AirportType? type, int limit})
    >((ref, params) {
      final repository = ref.watch(airportRepositoryProvider);
      return repository.searchAirports(
        query: params.query,
        countryCode: params.countryCode,
        type: params.type,
        limit: params.limit,
      );
    });

/// Stream of airports near coordinates
final airportsNearStreamProvider =
    StreamProvider.family<
      List<Airport>,
      ({double latitude, double longitude, double delta, int limit})
    >((ref, params) {
      final repository = ref.watch(airportRepositoryProvider);
      return repository.watchAirportsNear(
        params.latitude,
        params.longitude,
        delta: params.delta,
        limit: params.limit,
      );
    });

/// Full details (airport, country, region, runways, frequencies) for one
/// airport. Resolves to null if the airport doesn't exist.
final airportDetailsProvider = FutureProvider.autoDispose
    .family<AirportWithEverything?, int>((ref, airportId) {
      return ref
          .watch(airportServiceProvider)
          .getCompleteAirportData(airportId);
    });

/// Stream of all countries
final countriesStreamProvider = StreamProvider<List<Country>>((ref) {
  final repository = ref.watch(airportRepositoryProvider);
  return repository.watchCountries();
});

// ---------------------------------------------------------------------------
// OurAirports download / sync
// ---------------------------------------------------------------------------

/// Progress of the OurAirports sync. Watching it starts the (daily) sync.
class AirportLoadNotifier extends Notifier<SyncProgress> {
  late AirportsService _service;

  @override
  SyncProgress build() {
    _service = ref.watch(airportServiceProvider);
    void onChange() => state = _service.progress.value;
    _service.progress.addListener(onChange);
    ref.onDispose(() => _service.progress.removeListener(onChange));
    // Deferred: loadData updates progress synchronously, which must not
    // happen while this provider is building.
    Future.microtask(_service.loadData);
    return _service.progress.value;
  }

  Future<void> refresh() => _service.loadData(forceDownload: true);
}

final airportLoadProvider = NotifierProvider<AirportLoadNotifier, SyncProgress>(
  AirportLoadNotifier.new,
);

final airportServiceProvider = Provider<AirportsService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = AirportsService(db);
  ref.onDispose(service.dispose);
  return service;
});
