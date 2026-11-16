import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight_track.dart';
import 'adsb_track_source.dart';

/// The OpenSky Network (https://openskynetwork.github.io/opensky-api/rest.html):
/// the flights of an aircraft, or of an airport, and the track of a flight,
/// for the last 30 days.
///
/// It answers anyone, but sparingly: every request costs credits out of a
/// daily allowance, and the older the day asked for the more it costs. An
/// OpenSky account's API client (client id and secret, OAuth2 client
/// credentials) gets ten times the anonymous allowance. Non-commercial use
/// only.
class OpenSkySource extends AdsbTrackSource {
  OpenSkySource({this.clientId, this.clientSecret});

  final String? clientId;
  final String? clientSecret;

  static const _host = 'opensky-network.org';
  static final _tokenUri = Uri.https(
    'auth.opensky-network.org',
    '/auth/realms/opensky-network/protocol/openid-connect/token',
  );

  /// The longest stretch the flight lists accept.
  static const _maxInterval = Duration(days: 2);

  /// A track has a waypoint at least every 15 minutes in flight, so a longer
  /// silence is the ground between two flights.
  static const _legGap = Duration(minutes: 30);

  /// Flights are listed by a nightly batch: the ones of the last day or so
  /// may only be reachable as tracks.
  static const _batchDelay = Duration(hours: 36);

  String? _token;
  DateTime? _tokenExpiry;

  @override
  AdsbProvider get provider => AdsbProvider.openSky;

  bool get hasCredentials =>
      (clientId?.trim().isNotEmpty ?? false) &&
      (clientSecret?.trim().isNotEmpty ?? false);

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------

  /// Asks OpenSky for an access token, which also tells whether it accepts
  /// the credentials. Returns the token and how long it lasts.
  static Future<(String, Duration)> requestToken(
    http.Client client,
    String clientId,
    String clientSecret,
  ) async {
    final http.Response response;
    try {
      response = await client
          .post(
            _tokenUri,
            body: {
              'grant_type': 'client_credentials',
              'client_id': clientId.trim(),
              'client_secret': clientSecret.trim(),
            },
          )
          .timeout(AdsbTrackSource.timeout);
    } catch (_) {
      throw const AdsbException(
        'Could not reach OpenSky. Check your connection.',
      );
    }
    final json = AdsbTrackSource.tryJson(response);
    final token = AdsbTrackSource.text(json, 'access_token');
    if (response.statusCode == 200 && token != null) {
      final lifetime = json is Map<String, dynamic> ? json['expires_in'] : null;
      return (
        token,
        Duration(seconds: lifetime is num ? lifetime.toInt() : 1800),
      );
    }
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const AdsbException(
        'OpenSky turned the client ID or secret down.',
        needsSetup: true,
      );
    }
    throw AdsbException(
      'OpenSky could not sign in (HTTP ${response.statusCode}).',
    );
  }

  Future<Map<String, String>> _headers(
    http.Client client, {
    bool renew = false,
  }) async {
    if (!hasCredentials) return const {};
    final expiry = _tokenExpiry;
    if (renew ||
        _token == null ||
        expiry == null ||
        !DateTime.now().isBefore(expiry)) {
      final (token, lifetime) = await requestToken(
        client,
        clientId!,
        clientSecret!,
      );
      _token = token;
      // Renewed a little early, so it never runs out mid-request.
      _tokenExpiry = DateTime.now().add(lifetime - const Duration(minutes: 1));
    }
    return {'Authorization': 'Bearer $_token'};
  }

  /// The JSON at [path], or null when OpenSky has nothing there (404).
  Future<Object?> _get(
    http.Client client,
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.https(_host, path, query);
    Future<http.Response> send({bool renew = false}) async {
      final headers = await _headers(client, renew: renew);
      try {
        return await client
            .get(uri, headers: headers)
            .timeout(AdsbTrackSource.timeout);
      } catch (_) {
        throw const AdsbException(
          'Could not reach OpenSky. Check your connection.',
        );
      }
    }

    var response = await send();
    // The token ran out, or was revoked: one more go with a new one.
    if (response.statusCode == 401 && hasCredentials) {
      response = await send(renew: true);
    }
    switch (response.statusCode) {
      case 200:
        return AdsbTrackSource.tryJson(response);
      case 404:
        return null;
      case 401 || 403:
        throw AdsbException(
          hasCredentials
              ? 'OpenSky turned the client ID or secret down.'
              : 'OpenSky refused the request. Add an API client to use it.',
          needsSetup: true,
        );
      case 429:
        throw AdsbException(
          _allowanceMessage(response),
          needsSetup: !hasCredentials,
        );
      default:
        throw AdsbException(
          'OpenSky could not answer (HTTP ${response.statusCode}).',
        );
    }
  }

  String _allowanceMessage(http.Response response) {
    final seconds = int.tryParse(
      response.headers['x-rate-limit-retry-after-seconds'] ?? '',
    );
    final wait = switch (seconds) {
      null => '',
      < 5400 => ' Try again in about ${(seconds / 60).ceil()} min.',
      _ => ' Try again in about ${(seconds / 3600).ceil()} h.',
    };
    return hasCredentials
        ? "OpenSky's daily allowance is used up.$wait"
        : "OpenSky's allowance for anonymous use is used up.$wait An API "
              'client gets ten times as much.';
  }

  static Map<String, String> _interval(AdsbWindow window) {
    final begin = window.from;
    final end = window.to.difference(begin) > _maxInterval
        ? begin.add(_maxInterval)
        : window.to;
    return {
      'begin': '${AdsbTrackSource.unixSeconds(begin)}',
      'end': '${AdsbTrackSource.unixSeconds(end)}',
    };
  }

  // ---------------------------------------------------------------------------
  // AdsbTrackSource
  // ---------------------------------------------------------------------------

  @override
  Future<List<AdsbFlight>> flightsOfAircraft(
    http.Client client,
    String icao24,
    AdsbWindow window,
  ) async {
    final json = await _get(client, '/api/flights/aircraft', {
      'icao24': icao24,
      ..._interval(window),
    });
    final flights = parseFlights(json);
    if (flights.isNotEmpty) return flights;

    // Too recent for the nightly batch: the track itself may be there
    // already, if the logbook says when to look.
    final start = window.expectedStart;
    final end = window.expectedEnd ?? start;
    if (start == null ||
        end == null ||
        end.isBefore(DateTime.now().subtract(_batchDelay))) {
      return const [];
    }
    final middle = start.add(end.difference(start) ~/ 2);
    final track = await _track(client, icao24, middle);
    if (track == null) return const [];
    final (callsign, points) = track;
    final leg = legAround(points, middle);
    if (leg.length < 2) return const [];
    return [
      AdsbFlight(
        provider: provider,
        icao24: icao24,
        start: leg.first.time,
        end: leg.last.time,
        callsign: callsign,
        points: leg,
      ),
    ];
  }

  @override
  Future<List<AdsbFlight>> flightsOfCallsign(
    http.Client client,
    String callsign,
    AdsbWindow window, {
    String? departureIcao,
    String? arrivalIcao,
  }) async {
    // OpenSky can't be asked for a callsign, only for what left or reached
    // an airport.
    final (path, airport) = switch ((departureIcao, arrivalIcao)) {
      (final departure?, _) => ('/api/flights/departure', departure),
      (_, final arrival?) => ('/api/flights/arrival', arrival),
      _ => throw const AdsbException(
        'OpenSky finds a flight number only among the flights of an airport: '
        'give the departure or arrival airport.',
      ),
    };
    final json = await _get(client, path, {
      'airport': airport.toUpperCase(),
      ..._interval(window),
    });
    final wanted = AdsbTrackSource.normalizeCallsign(callsign);
    final flights = parseFlights(json);
    final matching = [
      for (final flight in flights)
        if (flight.callsign != null &&
            AdsbTrackSource.normalizeCallsign(flight.callsign!) == wanted)
          flight,
    ];
    if (matching.isNotEmpty || departureIcao == null || arrivalIcao == null) {
      return matching;
    }
    // Nothing flew as that callsign (low-cost airlines mostly transmit
    // callsigns that aren't the flight number): what left for the arrival
    // airport is the next best thing, and what landed out of reach may be
    // it too (see AdsbTrackService.searchCallsign).
    final arrival = arrivalIcao.toUpperCase();
    return [
      for (final flight in flights)
        if (flight.arrival == null || flight.arrival!.toUpperCase() == arrival)
          flight.foundByRoute(),
    ];
  }

  @override
  Future<List<TrackPoint>> track(http.Client client, AdsbFlight flight) async {
    if (flight.points != null) return flight.points!;
    final middle = flight.start.add(flight.duration ~/ 2);
    final track = await _track(client, flight.icao24, middle);
    if (track == null) {
      throw const AdsbException(
        'OpenSky has no track for this flight. It keeps tracks for 30 days.',
      );
    }
    final points = track.$2;
    // The track can run on into what the aircraft did next: keep the
    // flight that was asked for.
    const margin = Duration(minutes: 2);
    final from = flight.start.subtract(margin);
    final to = flight.end.add(margin);
    final within = [
      for (final point in points)
        if (!point.time.isBefore(from) && !point.time.isAfter(to)) point,
    ];
    return within.length >= 2 ? within : legAround(points, middle);
  }

  /// The track of the flight [icao24] was on at [time]: its callsign and
  /// positions. Null when OpenSky knows of none.
  Future<(String?, List<TrackPoint>)?> _track(
    http.Client client,
    String icao24,
    DateTime time,
  ) async {
    final json = await _get(client, '/api/tracks/all', {
      'icao24': icao24,
      'time': '${AdsbTrackSource.unixSeconds(time)}',
    });
    if (json is! Map<String, dynamic>) return null;
    // "calllsign" is how their documentation spells it.
    final callsign =
        AdsbTrackSource.text(json, 'callsign') ??
        AdsbTrackSource.text(json, 'calllsign');
    return (callsign, parsePath(json['path']));
  }

  // ---------------------------------------------------------------------------
  // Answers
  // ---------------------------------------------------------------------------

  /// Reads a list of flights (`/flights/aircraft`, `/flights/departure`,
  /// `/flights/arrival`), oldest first.
  List<AdsbFlight> parseFlights(Object? json) {
    if (json is! List) return const [];
    final flights = <AdsbFlight>[];
    for (final flight in json.whereType<Map<String, dynamic>>()) {
      final icao24 = AdsbTrackSource.normalizeHex(
        AdsbTrackSource.text(flight, 'icao24'),
      );
      final first = flight['firstSeen'];
      final last = flight['lastSeen'];
      if (icao24 == null || first is! num || last is! num) continue;
      flights.add(
        AdsbFlight(
          provider: provider,
          icao24: icao24,
          start: AdsbTrackSource.fromUnix(first),
          end: AdsbTrackSource.fromUnix(last),
          callsign: AdsbTrackSource.text(flight, 'callsign'),
          departure: AdsbTrackSource.text(flight, 'estDepartureAirport'),
          arrival: AdsbTrackSource.text(flight, 'estArrivalAirport'),
        ),
      );
    }
    return flights..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Reads the `path` of a track: waypoints of `[time, latitude, longitude,
  /// barometric altitude (m), true track (°), on ground]`. OpenSky gives no
  /// speed, so it is worked out from the waypoints.
  static List<TrackPoint> parsePath(Object? path) {
    if (path is! List) return const [];
    final points = <TrackPoint>[];
    for (final waypoint in path) {
      if (waypoint is! List || waypoint.length < 3) continue;
      final time = waypoint[0];
      final lat = waypoint[1];
      final lon = waypoint[2];
      if (time is! num || lat is! num || lon is! num) continue;
      final altitude = waypoint.length > 3 ? waypoint[3] : null;
      final heading = waypoint.length > 4 ? waypoint[4] : null;
      final onGround = waypoint.length > 5 && waypoint[5] == true;
      points.add(
        TrackPoint(
          time: AdsbTrackSource.fromUnix(time),
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
          altitude: altitude is num && !onGround ? altitude.toDouble() : null,
          heading: heading is num ? heading.toDouble() : null,
          onGround: onGround,
        ),
      );
    }
    return TrackTools.fillSpeeds(TrackTools.clean(points));
  }

  /// The stretch of [points] flown around [time]: a track can hold more
  /// than one flight.
  static List<TrackPoint> legAround(List<TrackPoint> points, DateTime time) {
    final legs = TrackTools.splitAtGaps(points, _legGap);
    if (legs.isEmpty) return const [];
    Duration distance(List<TrackPoint> leg) {
      if (time.isBefore(leg.first.time)) return leg.first.time.difference(time);
      if (time.isAfter(leg.last.time)) return time.difference(leg.last.time);
      return Duration.zero;
    }

    return legs.reduce((a, b) => distance(b) < distance(a) ? b : a);
  }
}

/// The client id and secret OpenSky hands out, as typed or pasted.
class OpenSkyCredentials {
  const OpenSkyCredentials(this.clientId, this.clientSecret);
  final String clientId;
  final String clientSecret;

  /// Reads the `credentials.json` OpenSky offers for download
  /// (`{"clientId": "...", "clientSecret": "..."}`), so it can be pasted
  /// whole. Null when [text] isn't one.
  static OpenSkyCredentials? fromJson(String text) {
    final Object? json;
    try {
      json = jsonDecode(text.trim());
    } on FormatException {
      return null;
    }
    final id =
        AdsbTrackSource.text(json, 'clientId') ??
        AdsbTrackSource.text(json, 'client_id');
    final secret =
        AdsbTrackSource.text(json, 'clientSecret') ??
        AdsbTrackSource.text(json, 'client_secret');
    return id == null || secret == null ? null : OpenSkyCredentials(id, secret);
  }
}
