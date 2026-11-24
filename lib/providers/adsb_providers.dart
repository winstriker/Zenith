import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/sync_progress.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/adsb_flight_importer.dart';
import '../services/adsb_flyitalyadsb_source.dart';
import '../services/adsb_opensky_source.dart';
import '../services/adsb_track_service.dart';
import '../services/adsb_track_source.dart';
import '../services/aircraft_hex_resolver.dart';
import '../services/aircraft_lookup_service.dart';
import '../services/aircraft_registry_service.dart';
import '../services/callsign_route_lookup.dart';
import '../services/database.dart';
import '../services/registry_database.dart';
import '../services/secret_store.dart';
import 'airport_providers.dart';
import 'database_provider.dart';
import 'provider_toggles.dart';

/// Makes the HTTP client of a one-off request (checking a key, say).
/// Overridden in tests.
final httpClientFactoryProvider = Provider<http.Client Function()>((ref) {
  return http.Client.new;
});

// ---------------------------------------------------------------------------
// Credentials
// ---------------------------------------------------------------------------

/// What the user entered to use the ADS-B providers with their own
/// accounts.
@immutable
class AdsbCredentials {
  const AdsbCredentials({
    this.flyItalyApiKey,
    this.openSkyClientId,
    this.openSkyClientSecret,
  });

  final String? flyItalyApiKey;
  final String? openSkyClientId;
  final String? openSkyClientSecret;

  bool get hasFlyItalyKey => flyItalyApiKey != null;
  bool get hasOpenSky => openSkyClientId != null && openSkyClientSecret != null;
}

class AdsbCredentialsNotifier extends AsyncNotifier<AdsbCredentials> {
  static const _flyItalyKey = 'flyitalyadsb_api_key';
  static const _openSkyId = 'opensky_client_id';
  static const _openSkySecret = 'opensky_client_secret';

  @override
  Future<AdsbCredentials> build() async {
    final store = ref.watch(secretStoreProvider);
    try {
      return AdsbCredentials(
        flyItalyApiKey: await store.read(_flyItalyKey),
        openSkyClientId: await store.read(_openSkyId),
        openSkyClientSecret: await store.read(_openSkySecret),
      );
    } catch (_) {
      // A keystore that can't be read (restored onto another device, say)
      // is the same as nothing entered: the user enters it again.
      return const AdsbCredentials();
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Saves the FlyItalyADSB API key, or forgets it when [key] is null.
  Future<void> setFlyItalyApiKey(String? key) async {
    final current = await future;
    await ref.read(secretStoreProvider).write(_flyItalyKey, key);
    state = AsyncData(
      AdsbCredentials(
        flyItalyApiKey: _clean(key),
        openSkyClientId: current.openSkyClientId,
        openSkyClientSecret: current.openSkyClientSecret,
      ),
    );
  }

  /// Saves the OpenSky API client, or forgets it when either part is null.
  Future<void> setOpenSky(String? clientId, String? clientSecret) async {
    final current = await future;
    final id = _clean(clientId);
    final secret = _clean(clientSecret);
    final both = id != null && secret != null;
    final store = ref.read(secretStoreProvider);
    await store.write(_openSkyId, both ? id : null);
    await store.write(_openSkySecret, both ? secret : null);
    state = AsyncData(
      AdsbCredentials(
        flyItalyApiKey: current.flyItalyApiKey,
        openSkyClientId: both ? id : null,
        openSkyClientSecret: both ? secret : null,
      ),
    );
  }
}

final adsbCredentialsProvider =
    AsyncNotifierProvider<AdsbCredentialsNotifier, AdsbCredentials>(
      AdsbCredentialsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Aircraft registry (tar1090-db) download
// ---------------------------------------------------------------------------

final registryDatabaseProvider = Provider<RegistryDatabase>((ref) {
  return RegistryDatabase();
});

final aircraftRegistryServiceProvider = Provider<AircraftRegistryService>((
  ref,
) {
  final service = AircraftRegistryService(ref.watch(registryDatabaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Progress of the aircraft registry download. Watching it starts the
/// (daily) check for a new list, as long as the local database is switched
/// on as a source of ICAO addresses.
class AircraftRegistryLoadNotifier extends Notifier<SyncProgress> {
  late AircraftRegistryService _service;

  @override
  SyncProgress build() {
    _service = ref.watch(aircraftRegistryServiceProvider);
    void onChange() => state = _service.progress.value;
    _service.progress.addListener(onChange);
    ref.onDispose(() => _service.progress.removeListener(onChange));

    // Switching the local database on downloads it.
    ref.listen(disabledHexSourcesProvider, (previous, next) {
      final wasOff = previous?.contains(LocalHexSource.sourceId) ?? false;
      if (wasOff && !next.contains(LocalHexSource.sourceId)) {
        unawaited(_service.loadData());
      }
    });
    // Deferred: loadData updates progress synchronously, which must not
    // happen while this provider is building.
    Future.microtask(() async {
      if (!ref.mounted || !_enabled) return;
      await _service.loadData();
    });
    return _service.progress.value;
  }

  bool get _enabled =>
      !ref.read(disabledHexSourcesProvider).contains(LocalHexSource.sourceId);

  /// Checks for a new list now.
  Future<void> refresh() => _service.loadData(force: true);

  /// Deletes the list from the device.
  Future<void> clear() async {
    await _service.clear();
    ref.invalidate(aircraftRegistryStatusProvider);
  }
}

final aircraftRegistryLoadProvider =
    NotifierProvider<AircraftRegistryLoadNotifier, SyncProgress>(
      AircraftRegistryLoadNotifier.new,
    );

/// What is on the device of the aircraft registry. Read again whenever a
/// download ends.
final aircraftRegistryStatusProvider = FutureProvider<RegistryStatus>((ref) {
  ref.watch(aircraftRegistryLoadProvider.select((progress) => progress.phase));
  return ref.watch(aircraftRegistryServiceProvider).status();
});

// ---------------------------------------------------------------------------
// ICAO address lookup
// ---------------------------------------------------------------------------

/// The sources of ICAO addresses the settings list.
final hexSourcesProvider = Provider<List<HexSource>>((ref) {
  return AircraftHexResolver.allSources(ref.watch(registryDatabaseProvider));
});

/// Asks the sources that are switched on.
final aircraftHexResolverProvider = Provider<AircraftHexResolver>((ref) {
  final off = ref.watch(disabledHexSourcesProvider);
  return AircraftHexResolver([
    for (final source in ref.watch(hexSourcesProvider))
      if (!off.contains(source.id)) source,
  ]);
});

// ---------------------------------------------------------------------------
// Tracks
// ---------------------------------------------------------------------------

/// The track providers that are switched on, set up with the user's
/// credentials. Kept alive between searches, so a sign-in is used for as
/// long as it lasts.
final adsbTrackSourcesProvider = FutureProvider<List<AdsbTrackSource>>((
  ref,
) async {
  final credentials = await ref.watch(adsbCredentialsProvider.future);
  final off = ref.watch(disabledTrackProvidersProvider);
  return [
    if (!off.contains(AdsbProvider.flyItalyAdsb.id))
      FlyItalyAdsbSource(
        apiKey: credentials.flyItalyApiKey,
        userAgent: appUserAgent,
      ),
    if (!off.contains(AdsbProvider.openSky.id))
      OpenSkySource(
        clientId: credentials.openSkyClientId,
        clientSecret: credentials.openSkyClientSecret,
      ),
  ];
});

final adsbTrackServiceProvider = FutureProvider<AdsbTrackService>((ref) async {
  final sources = await ref.watch(adsbTrackSourcesProvider.future);
  return AdsbTrackService(
    sources: sources,
    resolver: ref.watch(aircraftHexResolverProvider),
    // adsbdb is the route database: switched off with it.
    routeOf:
        ref.watch(disabledHexSourcesProvider).contains(AdsbdbSource.sourceId)
        ? null
        : adsbdbCallsignRoute,
  );
});

/// The track of a flight, in order. Empty for a flight without one.
final flightTrackProvider = StreamProvider.autoDispose
    .family<List<FlightDataPoint>, int>((ref, flightId) {
      return ref.watch(flightRepositoryProvider).watchTrack(flightId);
    });

// ---------------------------------------------------------------------------
// Import
// ---------------------------------------------------------------------------

/// Turns a flight found on ADS-B into a flight to log.
final adsbFlightImporterProvider = FutureProvider<AdsbFlightImporter>((
  ref,
) async {
  final service = await ref.watch(adsbTrackServiceProvider.future);
  final off = ref.watch(disabledHexSourcesProvider);
  final registry = ref.watch(registryDatabaseProvider);
  final database = ref.watch(databaseProvider);
  final airports = ref.watch(airportServiceProvider);
  final aircraft = ref.watch(aircraftRepositoryProvider);
  final newClient = ref.watch(httpClientFactoryProvider);

  return AdsbFlightImporter(
    fetchPoints: service.fetchPoints,
    airportByCode: database.findAirportByCode,
    airportsNear: (lat, lon) =>
        airports.getAirportsNearCoordinates(lat, lon, limit: 50),
    localRegistrations: (hex) async => off.contains(LocalHexSource.sourceId)
        ? const []
        : registry.registrationsFor(hex),
    onlineRegistration: (hex) async {
      // adsbdb answers for an ICAO address as it does for a registration.
      if (off.contains(AdsbdbSource.sourceId)) return null;
      final client = newClient();
      try {
        final found = await const AdsbdbSource().lookup(client, hex);
        final foundHex = AdsbTrackSource.normalizeHex(found?.icaoHex);
        // Six hex digits could be read as a registration: make sure it
        // answered for the address.
        if (foundHex != null && foundHex != hex) return null;
        return found?.registration;
      } finally {
        client.close();
      }
    },
    aircraft: () => aircraft.watchAircraftsWithStats().first,
  );
});
