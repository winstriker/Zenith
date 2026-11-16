import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/flight_track.dart';
import 'adsb_track_source.dart';
import 'aircraft_hex_resolver.dart';
import 'callsign_route_lookup.dart';

/// What a search for a flight's track came up with.
class AdsbSearchResult {
  const AdsbSearchResult({
    required this.flights,
    this.hexes = const [],
    this.problems = const {},
  });

  /// The flights the providers saw, oldest first.
  final List<AdsbFlight> flights;

  /// The ICAO addresses the registration was looked for under. Empty when
  /// the search wasn't by registration.
  final List<HexCandidate> hexes;

  /// The providers that could not be asked, and why.
  final Map<AdsbProvider, AdsbException> problems;
}

/// Finds the track of a flight on the ADS-B providers the user enabled:
/// from a registration (turned into an ICAO address first), an address, or
/// a callsign.
class AdsbTrackService {
  AdsbTrackService({
    required this.sources,
    required this.resolver,
    this.routeOf,
    this.httpClient,
  });

  /// The enabled providers, in order of preference.
  final List<AdsbTrackSource> sources;
  final AircraftHexResolver resolver;

  /// Where a callsign usually flies: settles where the flights found by
  /// route went when no receiver saw them land. Null when switched off.
  final CallsignRouteLookup? routeOf;

  /// The most callsigns [routeOf] is asked about in one search: what
  /// leaves a busy airport in a day, out of the receivers' reach, is
  /// around a hundred.
  static const maxRouteLookups = 150;

  /// What [routeOf] said of each callsign (normalized), null included:
  /// a callsign flies the same route day after day, and a second search
  /// needn't ask again.
  final _routes = <String, CallsignRoute?>{};

  /// Used for every request when given, e.g. in tests.
  final http.Client? httpClient;

  /// The fewest positions that make a track.
  static const _minPoints = 2;

  Future<T> _withClient<T>(Future<T> Function(http.Client client) run) async {
    final client = httpClient ?? http.Client();
    try {
      return await run(client);
    } finally {
      if (httpClient == null) client.close();
    }
  }

  void _requireSources() {
    if (sources.isEmpty) {
      throw const AdsbException(
        'No ADS-B provider is switched on.',
        needsSetup: true,
      );
    }
  }

  /// The flights of the aircraft registered as [registration] in [window].
  /// Throws when no source knows which ICAO address it has.
  Future<AdsbSearchResult> searchRegistration(
    String registration,
    AdsbWindow window,
  ) {
    _requireSources();
    return _withClient((client) async {
      if (resolver.sources.isEmpty) {
        throw const AdsbException(
          'Nothing is switched on to look up the ICAO address of a '
          'registration.',
          needsSetup: true,
        );
      }
      final resolution = await resolver.resolve(client, registration);
      if (resolution.candidates.isEmpty) {
        final failed = resolution.unreachable;
        throw AdsbException(
          'No ICAO address found for "${registration.trim().toUpperCase()}".'
          '${failed.isEmpty ? '' : ' Could not ask: ${failed.join(', ')}.'}',
        );
      }
      final hexes = [for (final c in resolution.candidates) c.hex];
      return _search((source) async {
        // Usually there is one address. When the sources disagree, the
        // first one the provider has flights for is the right one.
        for (final hex in hexes) {
          final flights = await source.flightsOfAircraft(client, hex, window);
          if (flights.isNotEmpty) return flights;
        }
        return const [];
      }, hexes: resolution.candidates);
    });
  }

  /// The flights of the aircraft with ICAO address [hex] in [window].
  Future<AdsbSearchResult> searchHex(String hex, AdsbWindow window) {
    _requireSources();
    final icao24 = AdsbTrackSource.normalizeHex(hex);
    if (icao24 == null) {
      throw const AdsbException(
        'An ICAO address is six hexadecimal digits, like 4CA242.',
      );
    }
    return _withClient(
      (client) =>
          _search((source) => source.flightsOfAircraft(client, icao24, window)),
    );
  }

  /// The flights flown as [callsign] in [window]. [departureIcao] and
  /// [arrivalIcao] are the flight's airports, when known.
  ///
  /// A provider that finds nothing under [callsign] may answer with the
  /// flights between the airports instead, those whose arrival it didn't
  /// see included. Those are checked against where their callsign usually
  /// flies: the ones known to go elsewhere are left out. When some flights
  /// are sure to have gone to [arrivalIcao], only those are kept.
  Future<AdsbSearchResult> searchCallsign(
    String callsign,
    AdsbWindow window, {
    String? departureIcao,
    String? arrivalIcao,
  }) {
    _requireSources();
    return _withClient((client) async {
      final result = await _search(
        (source) => source.flightsOfCallsign(
          client,
          callsign,
          window,
          departureIcao: departureIcao,
          arrivalIcao: arrivalIcao,
        ),
      );
      if (arrivalIcao == null) return result;
      return AdsbSearchResult(
        flights: await _confirmRoutes(client, result.flights, arrivalIcao),
        problems: result.problems,
      );
    });
  }

  /// See [searchCallsign].
  Future<List<AdsbFlight>> _confirmRoutes(
    http.Client client,
    List<AdsbFlight> flights,
    String arrivalIcao,
  ) async {
    final arrival = arrivalIcao.toUpperCase();
    bool unseen(AdsbFlight f) => f.byRoute && f.arrival == null;

    final callsigns = <String>{
      for (final flight in flights)
        if (unseen(flight) && flight.callsign != null)
          AdsbTrackSource.normalizeCallsign(flight.callsign!),
    }.where((c) => !_routes.containsKey(c)).take(maxRouteLookups).toList();
    final routes = _routes;
    final lookup = routeOf;
    if (lookup != null && callsigns.isNotEmpty) {
      // A few at a time: it's a free service.
      for (var i = 0; i < callsigns.length; i += 10) {
        final batch = callsigns.skip(i).take(10).toList();
        final answers = await Future.wait([
          for (final callsign in batch)
            lookup(client, callsign).then<(CallsignRoute?,)?>(
              (route) => (route,),
              // Couldn't be asked: not cached, to ask again next time.
              onError: (_) => null,
            ),
        ]);
        for (final (j, answer) in answers.indexed) {
          if (answer != null) routes[batch[j]] = answer.$1;
        }
      }
    }

    final sure = <AdsbFlight>[];
    final possible = <AdsbFlight>[];
    for (final flight in flights) {
      if (!unseen(flight)) {
        sure.add(flight);
        continue;
      }
      final callsign = flight.callsign;
      final destination = callsign == null
          ? null
          : routes[AdsbTrackSource.normalizeCallsign(callsign)]?.destination
                ?.toUpperCase();
      if (destination == null) {
        possible.add(flight);
      } else if (destination == arrival) {
        sure.add(flight.foundByRoute(arrival: destination));
      }
      // Else it went elsewhere.
    }
    return sure.isNotEmpty ? sure : possible;
  }

  /// Asks every provider at once. One that fails doesn't spoil what the
  /// others found.
  Future<AdsbSearchResult> _search(
    Future<List<AdsbFlight>> Function(AdsbTrackSource source) ask, {
    List<HexCandidate> hexes = const [],
  }) async {
    final problems = <AdsbProvider, AdsbException>{};
    final answers = await Future.wait([
      for (final source in sources)
        () async {
          try {
            return await ask(source);
          } on AdsbException catch (e) {
            problems[source.provider] = e;
          } catch (e) {
            problems[source.provider] = AdsbException(
              "${source.provider.label} sent something that can't be read.",
            );
          }
          return const <AdsbFlight>[];
        }(),
    ]);
    return AdsbSearchResult(
      flights: [for (final flights in answers) ...flights]
        ..sort((a, b) => a.start.compareTo(b.start)),
      hexes: hexes,
      problems: problems,
    );
  }

  /// The track of [flight], ready to be stored: in order, every point with
  /// an altitude and, where it can be worked out, a speed.
  /// [departureElevation] and [arrivalElevation] (metres) are those of the
  /// logged airports, for the points on the ground.
  Future<List<TrackPoint>> loadTrack(
    AdsbFlight flight, {
    double? departureElevation,
    double? arrivalElevation,
  }) async {
    return TrackTools.fillAltitudes(
      await fetchPoints(flight),
      departureElevation: departureElevation,
      arrivalElevation: arrivalElevation,
    );
  }

  /// The positions of [flight], in order and with speeds where they can be
  /// worked out, but with the altitudes as the provider sent them: null on
  /// the ground. For when the airports are only known from the track itself;
  /// [TrackTools.fillAltitudes] finishes the job.
  Future<List<TrackPoint>> fetchPoints(AdsbFlight flight) {
    final source = sources
        .where((s) => s.provider == flight.provider)
        .firstOrNull;
    if (source == null) {
      throw AdsbException(
        '${flight.provider.label} is switched off.',
        needsSetup: true,
      );
    }
    return _withClient((client) async {
      final points = TrackTools.clean(await source.track(client, flight));
      if (points.length < _minPoints) {
        throw AdsbException(
          '${flight.provider.label} has no positions for this flight.',
        );
      }
      return TrackTools.fillSpeeds(points);
    });
  }
}
