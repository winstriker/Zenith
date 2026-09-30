import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../repositories/airport_repository.dart';
import '../services/airport_service.dart';
import '../services/database.dart';

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

/// Stream of all countries
final countriesStreamProvider = StreamProvider<List<Country>>((ref) {
  final repository = ref.watch(airportRepositoryProvider);
  return repository.watchCountries();
});

// ---------------------------------------------------------------------------
// Legacy provider for airport download functionality
// ---------------------------------------------------------------------------

class AirportLoadNotifier extends Notifier<int> {
  late final AirportsService _service;

  @override
  int build() {
    _service = ref.watch(airportServiceProvider);
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

final airportLoadProvider = NotifierProvider<AirportLoadNotifier, int>(
  AirportLoadNotifier.new,
);

/// Legacy AirportsService provider (for download functionality)
final airportServiceProvider = Provider<AirportsService>((ref) {
  final db = ref.watch(databaseProvider);
  return AirportsService(db);
});
