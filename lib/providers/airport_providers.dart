import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/airport_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/airport_service.dart';
import '../services/database.dart';
import 'database_provider.dart';
import 'provider_toggles.dart';
import 'shared_preferences_provider.dart';

/// Whether airport searches leave out airports without an ICAO code (the
/// user's own airports are always kept). On by default.
class IcaoOnlyNotifier extends Notifier<bool> {
  static const prefsKey = 'airports_icao_only';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setBool(prefsKey, value);
  }
}

final icaoOnlyProvider = NotifierProvider<IcaoOnlyNotifier, bool>(
  IcaoOnlyNotifier.new,
);

const excludedAirportTypesKey = 'airports_excluded_types';

/// Airport types (`AirportType.name`) that searches leave out.
final excludedAirportTypeNamesProvider =
    NotifierProvider<DisabledIdsNotifier, Set<String>>(
      () => DisabledIdsNotifier(excludedAirportTypesKey),
    );

/// Airport types that searches leave out, unless one is asked for.
final excludedAirportTypesProvider = Provider<Set<AirportType>>((ref) {
  final names = ref.watch(excludedAirportTypeNamesProvider);
  return {
    for (final t in AirportType.values)
      if (names.contains(t.name)) t,
  };
});

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

/// Which part of the airport list a paged list shows.
typedef AirportsPageKey = ({
  int limit,
  String query,
  String? country,
  AirportType? type,
  bool customOnly,
  bool nearest,
});

/// The airports list: with no search or filter, the `limit` airports most
/// recently used, or with `nearest` those nearest to the user (most recently
/// used again without their position); otherwise the first `limit` matching
/// ones. Lists load more by asking a bigger `limit`.
final airportsPageProvider = StreamProvider.autoDispose
    .family<List<AirportWithDistance>, AirportsPageKey>((ref, key) {
      final filtering =
          key.query.isNotEmpty ||
          key.country != null ||
          key.type != null ||
          key.customOnly;
      final icaoOnly = ref.watch(icaoOnlyProvider);
      final excludedTypes = ref.watch(excludedAirportTypesProvider);
      if (!filtering) {
        final service = ref.watch(airportServiceProvider);
        return key.nearest
            ? service.watchNearAirportsWithFallback(
                limit: key.limit,
                icaoOnly: icaoOnly,
                excludedTypes: excludedTypes,
              )
            : service.watchRecentAirports(limit: key.limit);
      }
      return ref
          .watch(airportRepositoryProvider)
          .searchAirports(
            query: key.query,
            countryCode: key.country,
            type: key.type,
            customOnly: key.customOnly,
            icaoOnly: icaoOnly,
            excludedTypes: excludedTypes,
            limit: key.limit,
          )
          .map((list) => [for (final a in list) AirportWithDistance(a, -1)]);
    });

/// Full details (airport, country, region, runways, frequencies) for one
/// airport. Resolves to null if the airport doesn't exist.
final airportDetailsProvider = FutureProvider.autoDispose
    .family<AirportWithEverything?, int>((ref, airportId) {
      return ref
          .watch(airportServiceProvider)
          .getCompleteAirportData(airportId);
    });

/// Which part of an airport's flights a paged list shows.
typedef AirportFlightsPageKey = ({int airportId, int limit});

/// The newest `limit` flights that departed from or arrived at an airport.
/// Lists load older flights by asking a bigger `limit`.
final airportFlightsPageProvider = StreamProvider.autoDispose
    .family<List<FlightWithStats>, AirportFlightsPageKey>((ref, key) {
      return ref
          .watch(flightRepositoryProvider)
          .watchFlightsForAirport(key.airportId, limit: key.limit);
    });

/// How many flights departed from or arrived at each airport, by airport
/// id. Airports no flight used are left out.
final airportFlightCountsProvider = StreamProvider.autoDispose<Map<int, int>>(
  (ref) => ref.watch(airportRepositoryProvider).watchFlightCounts(),
);

/// Stream of the regions of a country, by name.
final regionsStreamProvider = StreamProvider.autoDispose
    .family<List<Region>, String>((ref, countryCode) {
      return ref.watch(airportRepositoryProvider).watchRegions(countryCode);
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
