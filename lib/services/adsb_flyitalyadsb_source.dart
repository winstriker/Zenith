import 'package:http/http.dart' as http;

import '../models/flight_track.dart';
import 'adsb_track_source.dart';

/// FlyItalyADSB (https://flyitalyadsb.com/data/api/): the track of an
/// aircraft for each UTC day, as readsb wrote it, and the flights seen
/// under a callsign or flight number. Every request needs the user's own
/// API key (free, by e-mail), which decides how far back it can go.
///
/// Written against their OpenAPI description:
/// https://github.com/flyitalyadsb/adsb-api/blob/main/openapi/openapi.json
class FlyItalyAdsbSource extends AdsbTrackSource {
  FlyItalyAdsbSource({required this.apiKey, this.userAgent});

  final String? apiKey;
  final String? userAgent;

  static const _host = 'api.flyitalyadsb.com';

  /// How far back `/flights/callsign` searches at most.
  static const maxCallsignDays = 14;

  /// How much around a flight found by callsign is kept of the day's track:
  /// its times are when it was seen near an airport, not first and last
  /// contact.
  static const _margin = Duration(minutes: 3);

  @override
  AdsbProvider get provider => AdsbProvider.flyItalyAdsb;

  bool get hasKey => apiKey != null && apiKey!.trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------

  /// The JSON object at [path], or null when FlyItalyADSB has nothing there
  /// (404).
  Future<Map<String, dynamic>?> _get(
    http.Client client,
    String path, [
    Map<String, String>? query,
  ]) async {
    if (!hasKey) {
      throw const AdsbException(
        'FlyItalyADSB needs an API key.',
        needsSetup: true,
      );
    }
    final http.Response response;
    try {
      response = await client
          .get(
            Uri.https(_host, path, query),
            headers: {'X-Api-Key': apiKey!.trim(), 'User-Agent': ?userAgent},
          )
          .timeout(AdsbTrackSource.timeout);
    } on AdsbException {
      rethrow;
    } catch (_) {
      throw const AdsbException(
        'Could not reach FlyItalyADSB. Check your connection.',
      );
    }
    final json = AdsbTrackSource.tryJson(response);
    if (response.statusCode == 404) return null;
    if (response.statusCode == 200 && json is Map<String, dynamic>) {
      return json;
    }
    throw _failure(response, json);
  }

  static AdsbException _failure(http.Response response, Object? json) {
    // Their errors say what is wrong in plain words ("error"), which beats
    // anything made up here.
    final said = AdsbTrackSource.text(json, 'error');
    return switch (response.statusCode) {
      401 => const AdsbException(
        'FlyItalyADSB turned the API key down.',
        needsSetup: true,
      ),
      429 => AdsbException(
        'FlyItalyADSB: ${said ?? 'too many requests'}. Try again shortly.',
      ),
      503 => const AdsbException('FlyItalyADSB is busy. Try again shortly.'),
      _ => AdsbException(
        'FlyItalyADSB: ${said ?? 'request refused (HTTP ${response.statusCode})'}',
      ),
    };
  }

  /// Whether FlyItalyADSB accepts [apiKey]. Throws when it can't be asked.
  static Future<bool> checkKey(
    http.Client client,
    String apiKey, {
    String? userAgent,
  }) async {
    final http.Response response;
    try {
      response = await client
          .get(
            // The cheapest question there is: an address nobody has.
            Uri.https(_host, '/v2/history/000000'),
            headers: {'X-Api-Key': apiKey.trim(), 'User-Agent': ?userAgent},
          )
          .timeout(AdsbTrackSource.timeout);
    } catch (_) {
      throw const AdsbException(
        'Could not reach FlyItalyADSB. Check your connection.',
      );
    }
    return response.statusCode != 401;
  }

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Everything FlyItalyADSB recorded of [icao24] on the UTC days from
  /// [from] to [to], in order.
  Future<List<TraceRow>> _rows(
    http.Client client,
    String icao24,
    DateTime from,
    DateTime to,
  ) async {
    final rows = <TraceRow>[];
    final today = DateTime.now().toUtc();
    for (final day in AdsbWindow(from, to).utcDays) {
      // The day hasn't started: there is nothing to ask for.
      if (day.isAfter(today)) break;
      final json = await _get(client, '/v2/history/$icao24/${_day(day)}');
      if (json != null) rows.addAll(parseTrace(json));
    }
    rows.sort((a, b) => a.point.time.compareTo(b.point.time));
    return rows;
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
    final rows = await _rows(client, icao24, window.from, window.to);
    return [
      for (final leg in splitLegs(rows))
        if (window.overlaps(leg.first.point.time, leg.last.point.time))
          AdsbFlight(
            provider: provider,
            icao24: icao24,
            start: leg.first.point.time,
            end: leg.last.point.time,
            callsign: leg.map((row) => row.callsign).nonNulls.firstOrNull,
            points: [for (final row in leg) row.point],
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
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final firstDay = window.utcDays.first;
    final daysBack = today.difference(firstDay).inDays;
    if (!window.from.isBefore(today)) {
      throw const AdsbException(
        "FlyItalyADSB lists a flight number's flights from the day after. "
        "Search today's flights by registration.",
      );
    }
    if (daysBack > maxCallsignDays) {
      throw const AdsbException(
        'FlyItalyADSB searches flight numbers at most $maxCallsignDays days '
        'back. Search older flights by registration.',
      );
    }
    final json = await _get(
      client,
      '/v2/flights/callsign/${Uri.encodeComponent(AdsbTrackSource.normalizeCallsign(callsign))}',
      {'days': '$daysBack'},
    );
    final found = parseObserved(json?['flights'], window);
    if (found.isNotEmpty || (departureIcao == null && arrivalIcao == null)) {
      return found;
    }
    // Nothing flew as that callsign: the airline may fly callsigns that
    // aren't the flight number. Look among the flights of the airports.
    return _flightsOfAirports(
      client,
      window,
      departureIcao: departureIcao,
      arrivalIcao: arrivalIcao,
      airlines: airlinePrefixes([callsign, ...?_strings(json?['tried'])]),
    );
  }

  static List<String>? _strings(Object? list) =>
      list is List ? list.whereType<String>().toList() : null;

  /// The ICAO airline codes in [callsigns]: "EZY" of "EZY3895". FlyItaly
  /// lists the forms it tried for a flight number ("U23895" → "EZY3895"),
  /// so this learns an airline's code from it rather than from a table.
  static Set<String> airlinePrefixes(Iterable<String> callsigns) => {
    for (final callsign in callsigns)
      if (RegExp(
            '^([A-Z]{3})[0-9]',
          ).firstMatch(AdsbTrackSource.normalizeCallsign(callsign))
          case final match?)
        match.group(1)!,
  };

  /// The flights that left [departureIcao] for [arrivalIcao] in [window],
  /// under any callsign, along with those whose arrival wasn't seen. With
  /// one airport only, the flights of that airport under a callsign of one
  /// of [airlines].
  Future<List<AdsbFlight>> _flightsOfAirports(
    http.Client client,
    AdsbWindow window, {
    String? departureIcao,
    String? arrivalIcao,
    required Set<String> airlines,
  }) async {
    final departure = departureIcao?.toUpperCase();
    final arrival = arrivalIcao?.toUpperCase();
    final both = departure != null && arrival != null;
    if (!both && airlines.isEmpty) return const [];
    final (code, type) = departure != null
        ? (departure, 'departures')
        : (arrival!, 'arrivals');

    final today = DateTime.now().toUtc();
    final found = <AdsbFlight>[];
    for (final day in window.utcDays) {
      // Only whole days are listed.
      if (!day.isBefore(DateTime.utc(today.year, today.month, today.day))) {
        break;
      }
      final json = await _get(
        client,
        '/v2/flights/airport/${Uri.encodeComponent(code)}',
        {'type': type, 'date': _day(day)},
      );
      for (final flight in parseObserved(json?['flights'], window)) {
        // Where a flight landed out of the network's reach is not known:
        // it may be the one (see AdsbTrackService.searchCallsign).
        final matches = both
            ? flight.arrival == null || flight.arrival!.toUpperCase() == arrival
            : airlines.any(
                (airline) => AdsbTrackSource.normalizeCallsign(
                  flight.callsign ?? '',
                ).startsWith(airline),
              );
        if (matches) found.add(flight.foundByRoute());
      }
    }
    return found..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Reads the `flights` of `/flights/callsign` and `/flights/airport`:
  /// those in [window], oldest first.
  List<AdsbFlight> parseObserved(Object? flights, AdsbWindow window) {
    if (flights is! List) return const [];
    final found = <AdsbFlight>[];
    for (final flight in flights.whereType<Map<String, dynamic>>()) {
      final icao24 = AdsbTrackSource.normalizeHex(
        AdsbTrackSource.text(flight, 'icao'),
      );
      final first = flight['first_seen'];
      final last = flight['last_seen'];
      if (icao24 == null || first is! num || last is! num) continue;
      final start = AdsbTrackSource.fromUnix(first);
      final end = AdsbTrackSource.fromUnix(last);
      if (!window.overlaps(start, end)) continue;
      found.add(
        AdsbFlight(
          provider: provider,
          icao24: icao24,
          start: start,
          end: end,
          callsign: AdsbTrackSource.text(flight, 'callsign'),
          departure: AdsbTrackSource.text(flight['from'], 'airport'),
          arrival: AdsbTrackSource.text(flight['to'], 'airport'),
        ),
      );
    }
    return found..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<TrackPoint>> track(http.Client client, AdsbFlight flight) async {
    if (flight.points != null) return flight.points!;
    final from = flight.start.subtract(_margin);
    final to = flight.end.add(_margin);
    final rows = await _rows(client, flight.icao24, from, to);
    return [
      for (final row in rows)
        if (!row.point.time.isBefore(from) && !row.point.time.isAfter(to))
          row.point,
    ];
  }

  // ---------------------------------------------------------------------------
  // readsb traces
  // ---------------------------------------------------------------------------

  /// Reads a readsb `trace_full` file: `timestamp` plus, for every position,
  /// `[seconds after timestamp, lat, lon, altitude (ft, or "ground"),
  /// ground speed (kt), track (°), flags, vertical rate, aircraft details,
  /// position source, geometric altitude (ft), ...]`.
  static List<TraceRow> parseTrace(Map<String, dynamic> json) {
    final base = json['timestamp'];
    final trace = json['trace'];
    if (base is! num || trace is! List) return const [];

    final raw = <_RawRow>[];
    var withGeometric = 0;
    var withBarometric = 0;
    for (final row in trace) {
      if (row is! List || row.length < 3) continue;
      final offset = row[0];
      final lat = row[1];
      final lon = row[2];
      if (offset is! num || lat is! num || lon is! num) continue;
      num? at(int i) => row.length > i && row[i] is num ? row[i] as num : null;
      final flags = at(6)?.toInt() ?? 0;
      final altitude = at(3);
      // Flag 8: the altitude field itself is geometric.
      final altitudeIsGeometric = flags & 8 != 0;
      final entry = _RawRow(
        time: AdsbTrackSource.fromUnix(base + offset),
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        barometric: altitudeIsGeometric ? null : altitude,
        geometric: at(10) ?? (altitudeIsGeometric ? altitude : null),
        onGround: row.length > 3 && row[3] == 'ground',
        speed: at(4),
        heading: at(5),
        newLeg: flags & 2 != 0,
        callsign: row.length > 8
            ? AdsbTrackSource.text(row[8], 'flight')
            : null,
      );
      if (entry.geometric != null) withGeometric++;
      if (entry.barometric != null) withBarometric++;
      raw.add(entry);
    }

    // The two altitudes differ by hundreds of feet on a day of high or low
    // pressure. Mixing them point by point would draw steps that were never
    // flown, so a track sticks to one kind: geometric (what the app's own
    // GPS recordings hold) when most points have it.
    final geometric = withGeometric >= withBarometric;
    return [
      for (final row in raw)
        TraceRow(
          TrackPoint(
            time: row.time,
            latitude: row.latitude,
            longitude: row.longitude,
            altitude: switch (geometric
                ? row.geometric ?? row.barometric
                : row.barometric ?? row.geometric) {
              final feet? when !row.onGround => feet * TrackTools.feetToMetres,
              _ => null,
            },
            speed: row.speed == null
                ? null
                : row.speed! * TrackTools.knotsToKmh,
            heading: row.heading?.toDouble(),
            onGround: row.onGround,
          ),
          newLeg: row.newLeg,
          callsign: row.callsign,
        ),
    ];
  }

  /// The longest silence a flight is put back together across: see
  /// [splitLegs].
  static const _rejoinGap = Duration(minutes: 90);

  /// Cuts a day's (or several days') rows into flights where readsb marked
  /// the start of a new leg. Stretches that never leave the ground (a tow,
  /// an engine run) are no flights and are left out.
  ///
  /// readsb also starts a new leg after a stretch out of coverage (over the
  /// sea, say). When the aircraft is in the air on both sides of such a cut,
  /// under the same callsign, it didn't land in between: the pieces are one
  /// flight.
  static List<List<TraceRow>> splitLegs(List<TraceRow> rows) {
    final legs = <List<TraceRow>>[];
    String? callsign;
    for (final row in rows) {
      if (legs.isEmpty ||
          (row.newLeg && !_continues(legs.last, callsign, row))) {
        legs.add([]);
        callsign = null;
      }
      legs.last.add(row);
      callsign = row.callsign ?? callsign;
    }
    return [
      for (final leg in legs)
        if (leg.length >= 2 && leg.any((row) => !row.point.onGround)) leg,
    ];
  }
}

/// Whether [row], which readsb marked as the start of a new leg, carries on
/// the flight of [leg], last seen as [callsign].
bool _continues(List<TraceRow> leg, String? callsign, TraceRow row) {
  final last = leg.last;
  if (last.point.onGround || row.point.onGround) return false;
  if (row.point.time.difference(last.point.time) >
      FlyItalyAdsbSource._rejoinGap) {
    return false;
  }
  final next = row.callsign;
  return callsign == null ||
      next == null ||
      AdsbTrackSource.normalizeCallsign(callsign) ==
          AdsbTrackSource.normalizeCallsign(next);
}

/// One position of a readsb trace, with what else its row says.
class TraceRow {
  const TraceRow(this.point, {this.newLeg = false, this.callsign});
  final TrackPoint point;

  /// readsb reckons a new flight starts here.
  final bool newLeg;
  final String? callsign;
}

class _RawRow {
  const _RawRow({
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.barometric,
    required this.geometric,
    required this.onGround,
    required this.speed,
    required this.heading,
    required this.newLeg,
    required this.callsign,
  });
  final DateTime time;
  final double latitude;
  final double longitude;

  /// Feet.
  final num? barometric;
  final num? geometric;
  final bool onGround;
  final num? speed;
  final num? heading;
  final bool newLeg;
  final String? callsign;
}
