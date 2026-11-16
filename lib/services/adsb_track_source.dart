import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight_track.dart';

/// The services flight tracks can be fetched from.
enum AdsbProvider {
  flyItalyAdsb(
    id: 'flyitalyadsb',
    label: 'FlyItalyADSB',
    // The wording their licence (CC BY-SA 4.0) asks for.
    attribution: 'Flight data: FlyItalyADSB (flyitalyadsb.com), CC BY-SA 4.0',
    website: 'https://flyitalyadsb.com',
  ),
  openSky(
    id: 'opensky',
    label: 'OpenSky Network',
    attribution: 'Flight data: The OpenSky Network (opensky-network.org)',
    website: 'https://opensky-network.org',
  );

  const AdsbProvider({
    required this.id,
    required this.label,
    required this.attribution,
    required this.website,
  });

  /// What is stored with a track (`Flights.trackSource`) and in the
  /// settings. Never change it.
  final String id;
  final String label;

  /// The credit to show wherever a track of this provider is shown.
  final String attribution;
  final String website;

  static AdsbProvider? byId(String? id) {
    for (final provider in values) {
      if (provider.id == id) return provider;
    }
    return null;
  }
}

/// A provider could not be asked, or refused. [message] is meant to be shown
/// to the user.
class AdsbException implements Exception {
  const AdsbException(this.message, {this.needsSetup = false});
  final String message;

  /// True when the way out is in the ADS-B settings: a key is missing or
  /// was turned down.
  final bool needsSetup;

  @override
  String toString() => message;
}

/// The stretch of time a flight is looked for in.
class AdsbWindow {
  AdsbWindow(
    DateTime from,
    DateTime to, {
    DateTime? expectedStart,
    this.expectedEnd,
  }) : from = from.toUtc(),
       to = to.toUtc(),
       expectedStart = expectedStart?.toUtc();

  /// The whole UTC day of [day], stretched to take in the flight the
  /// logbook has from [expectedStart] to [expectedEnd] when that flight is
  /// on that day: a flight that lands after midnight UTC is then found
  /// whole.
  factory AdsbWindow.forDay(
    DateTime day, {
    DateTime? expectedStart,
    DateTime? expectedEnd,
  }) {
    var from = DateTime.utc(day.year, day.month, day.day);
    var to = from.add(const Duration(days: 1));
    final start = expectedStart?.toUtc();
    final end = (expectedEnd ?? expectedStart)?.toUtc();
    // Only when the logged flight has to do with that day at all, and is a
    // believable flight: never stretch the search over many days.
    if (start != null &&
        end != null &&
        !end.isBefore(start) &&
        end.difference(start) < const Duration(hours: 24) &&
        start.isBefore(to) &&
        end.isAfter(from)) {
      if (start.isBefore(from)) from = start;
      if (end.isAfter(to)) to = end;
      return AdsbWindow(from, to, expectedStart: start, expectedEnd: end);
    }
    return AdsbWindow(from, to);
  }

  final DateTime from;
  final DateTime to;

  /// When the flight took place according to the logbook, if it says.
  final DateTime? expectedStart;
  final DateTime? expectedEnd;

  /// Midnight of every UTC day the window touches.
  List<DateTime> get utcDays {
    final days = <DateTime>[];
    var day = DateTime.utc(from.year, from.month, from.day);
    // `to` is exclusive: a window ending at midnight doesn't need that day.
    while (day.isBefore(to)) {
      days.add(day);
      day = day.add(const Duration(days: 1));
    }
    return days;
  }

  bool overlaps(DateTime start, DateTime end) =>
      !start.isAfter(to) && !end.isBefore(from);
}

/// A flight a provider saw.
class AdsbFlight {
  const AdsbFlight({
    required this.provider,
    required this.icao24,
    required this.start,
    required this.end,
    this.callsign,
    this.departure,
    this.arrival,
    this.points,
    this.byRoute = false,
    this.arrivalUnseen = false,
  });

  final AdsbProvider provider;

  /// 24-bit ICAO address of the aircraft, six lower case hex digits.
  final String icao24;
  final String? callsign;

  /// First and last time the provider saw the flight, UTC.
  final DateTime start;
  final DateTime end;

  /// Airports the provider reckons the flight went between (ICAO codes).
  final String? departure;
  final String? arrival;

  /// The track, when it came along with the flight. Otherwise
  /// [AdsbTrackSource.track] fetches it.
  final List<TrackPoint>? points;

  /// Found among the flights between the airports of a callsign search,
  /// not by the callsign itself: low-cost airlines mostly transmit
  /// callsigns that aren't the flight number.
  final bool byRoute;

  /// [arrival] is where the callsign usually goes, not where the aircraft
  /// was seen landing: no receiver saw the end of the flight, and [end] is
  /// only when it was last heard.
  final bool arrivalUnseen;

  /// This flight, marked as found by route, with [arrival] when it is
  /// known only from where its callsign usually goes.
  AdsbFlight foundByRoute({String? arrival}) => AdsbFlight(
    provider: provider,
    icao24: icao24,
    start: start,
    end: end,
    callsign: callsign,
    departure: departure,
    arrival: arrival ?? this.arrival,
    points: points,
    byRoute: true,
    arrivalUnseen: arrivalUnseen || arrival != null,
  );

  Duration get duration => end.difference(start);

  /// How much of the flight falls between [from] and [to].
  Duration overlapWith(DateTime from, DateTime to) {
    final a = start.isAfter(from) ? start : from;
    final b = end.isBefore(to) ? end : to;
    return b.isAfter(a) ? b.difference(a) : Duration.zero;
  }
}

/// A service that keeps flight tracks.
abstract class AdsbTrackSource {
  AdsbProvider get provider;

  static const timeout = Duration(seconds: 30);

  /// The flights of the aircraft with address [icao24] in [window], oldest
  /// first. Empty when the provider saw none.
  Future<List<AdsbFlight>> flightsOfAircraft(
    http.Client client,
    String icao24,
    AdsbWindow window,
  );

  /// The flights flown as [callsign] (or flight number, where the provider
  /// understands those) in [window]. [departureIcao] and [arrivalIcao] are
  /// the airports of the flight, when known: some providers can only search
  /// by airport. When nothing flew as [callsign], a source may answer with
  /// the flights between those airports instead ([AdsbFlight.byRoute]).
  Future<List<AdsbFlight>> flightsOfCallsign(
    http.Client client,
    String callsign,
    AdsbWindow window, {
    String? departureIcao,
    String? arrivalIcao,
  });

  /// The positions of [flight], which this source returned.
  Future<List<TrackPoint>> track(http.Client client, AdsbFlight flight);

  // ---------------------------------------------------------------------------
  // Shared by the sources
  // ---------------------------------------------------------------------------

  /// "ryr 4wy" → "RYR4WY".
  static String normalizeCallsign(String callsign) =>
      callsign.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// "4CA242 " → "4ca242", or null when it isn't a 24-bit address.
  static String? normalizeHex(String? hex) {
    final value = hex?.trim().toLowerCase();
    return value != null && RegExp(r'^[0-9a-f]{6}$').hasMatch(value)
        ? value
        : null;
  }

  static int unixSeconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

  static DateTime fromUnix(num seconds) => DateTime.fromMillisecondsSinceEpoch(
    (seconds * 1000).round(),
    isUtc: true,
  );

  /// The JSON in [response], or null when there is none worth the name
  /// (an HTML error page, say).
  static Object? tryJson(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  static String? text(Object? map, String key) {
    final value = map is Map<String, dynamic> ? map[key] : null;
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
