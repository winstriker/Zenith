import 'package:http/http.dart' as http;

import 'adsb_track_source.dart';

/// Where a callsign usually flies, as a route database has it.
class CallsignRoute {
  const CallsignRoute({this.origin, this.destination});

  /// ICAO codes.
  final String? origin;
  final String? destination;
}

/// Looks up the route a callsign usually flies.
typedef CallsignRouteLookup =
    Future<CallsignRoute?> Function(http.Client client, String callsign);

/// adsbdb's route database (https://www.adsbdb.com): crowd-sourced, so it
/// knows the alphanumeric callsigns of low-cost airlines ("EJU54JF") too.
/// Null when it doesn't know the callsign.
Future<CallsignRoute?> adsbdbCallsignRoute(
  http.Client client,
  String callsign,
) async {
  final response = await client
      .get(
        Uri.https(
          'api.adsbdb.com',
          '/v0/callsign/${Uri.encodeComponent(AdsbTrackSource.normalizeCallsign(callsign))}',
        ),
      )
      .timeout(AdsbTrackSource.timeout);
  if (response.statusCode != 200) return null;
  return parseAdsbdbRoute(AdsbTrackSource.tryJson(response));
}

/// Reads adsbdb's `/v0/callsign` answer.
CallsignRoute? parseAdsbdbRoute(Object? json) {
  final response = json is Map<String, dynamic> ? json['response'] : null;
  final route = response is Map<String, dynamic>
      ? response['flightroute']
      : null;
  if (route is! Map<String, dynamic>) return null;
  final origin = AdsbTrackSource.text(route['origin'], 'icao_code');
  final destination = AdsbTrackSource.text(route['destination'], 'icao_code');
  if (origin == null && destination == null) return null;
  return CallsignRoute(origin: origin, destination: destination);
}
