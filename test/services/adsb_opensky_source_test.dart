import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/services/adsb_opensky_source.dart';
import 'package:zenith/services/adsb_track_source.dart';

// Real answers of OpenSky (13 November 2026), shortened.

/// https://opensky-network.org/api/flights/aircraft?icao24=3c6743&begin=…&end=…
/// Newest first, as it comes.
const _flights = [
  {
    'icao24': '3c6743',
    'firstSeen': 1794577238,
    'estDepartureAirport': 'LHBP',
    'lastSeen': 1794582260,
    'estArrivalAirport': 'EDDF',
    'callsign': 'DLH2EV  ',
    'estDepartureAirportHorizDistance': 937,
    'departureAirportCandidatesCount': 63,
  },
  {
    'icao24': '3c6743',
    'firstSeen': 1794559212,
    'estDepartureAirport': 'LIMC',
    'lastSeen': 1794562542,
    'estArrivalAirport': 'EDDF',
    'callsign': 'DLH2EF  ',
    'estDepartureAirportHorizDistance': 1033,
    'departureAirportCandidatesCount': 71,
  },
  {
    'icao24': '3c6743',
    'firstSeen': 1794552027,
    'estDepartureAirport': 'EDDF',
    'lastSeen': 1794555592,
    'estArrivalAirport': null,
    'callsign': 'DLH246  ',
  },
];

/// https://opensky-network.org/api/tracks/all?icao24=3c6743&time=1794560800
/// Waypoints: [time, latitude, longitude, baro altitude m, true track,
/// on ground]. The end is as it came: three waypoints of the same second
/// with altitudes all over the place, then one two hours later, from the
/// aircraft's next flight.
const _track = {
  'icao24': '3c6743',
  'callsign': 'DLH2EF  ',
  'startTime': 1794559212.0,
  'endTime': 1794568848.0,
  'path': [
    [1794559212, 45.6354, 8.7321, 304, 349, false],
    [1794559227, 45.646, 8.7292, 304, 349, false],
    [1794559230, 45.6487, 8.7286, 609, 351, false],
    [1794559989, 46.6346, 8.9793, 8839, 354, false],
    [1794560035, 46.7249, 8.9672, 9144, 354, false],
    [1794560997, 48.6002, 9.049, 7620, 8, false],
    [1794561671, 49.6386, 9.2937, 3048, 7, false],
    [1794562219, 50.1187, 8.9331, 1524, 265, false],
    [1794562466, 50.061, 8.654, 304, 249, false],
    [1794562498, 50.0544, 8.626, 304, 250, false],
    [1794562542, 50.0451, 8.5868, 0, 249, false],
    [1794562542, 50.0451, 8.5868, 10058, 249, false],
    [1794562542, 50.0451, 8.5868, 4267, 249, false],
    [1794568848, 50.0006, 8.5263, 304, 179, false],
  ],
};

final _day = DateTime.utc(2026, 11, 13);

http.Response _json(
  Object? body, [
  int status = 200,
  Map<String, String> headers = const {},
]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: headers,
);

void main() {
  test(
    "an aircraft's flights are listed oldest first, without asking for tracks",
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return _json(_flights);
      });

      final flights = await OpenSkySource().flightsOfAircraft(
        client,
        '3c6743',
        AdsbWindow.forDay(_day),
      );

      final url = requests.single.url;
      expect(url.host, 'opensky-network.org');
      expect(url.path, '/api/flights/aircraft');
      expect(url.queryParameters, {
        'icao24': '3c6743',
        'begin': '1794528000',
        'end': '1794614400',
      });
      // Nobody signed in: no token is asked for, none is sent.
      expect(requests.single.headers.containsKey('Authorization'), isFalse);

      expect(flights.map((f) => f.callsign), ['DLH246', 'DLH2EF', 'DLH2EV']);
      final flight = flights[1];
      expect(flight.provider, AdsbProvider.openSky);
      expect(flight.start, DateTime.utc(2026, 11, 13, 8, 40, 12));
      expect(flight.end, DateTime.utc(2026, 11, 13, 9, 35, 42));
      expect(flight.departure, 'LIMC');
      expect(flight.arrival, 'EDDF');
      expect(flights.first.arrival, isNull);
      expect(flight.points, isNull);
    },
  );

  test(
    "a flight's track is asked for in its middle and kept to the flight",
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return request.url.path == '/api/tracks/all'
            ? _json(_track)
            : _json(_flights);
      });
      final source = OpenSkySource();
      final flight = (await source.flightsOfAircraft(
        client,
        '3c6743',
        AdsbWindow.forDay(_day),
      ))[1];

      final points = await source.track(client, flight);

      expect(requests.last.path, '/api/tracks/all');
      expect(requests.last.queryParameters, {
        'icao24': '3c6743',
        'time': '1794560877',
      });
      // One waypoint per second, and nothing of the next flight.
      expect(points, hasLength(11));
      expect(points.first.time, flight.start);
      expect(points.last.time, flight.end);
      expect(points[3].altitude, 8839);
      expect(points[3].heading, 354);
      // OpenSky sends no speed: it comes from the waypoints. An airliner on
      // the climb out of Malpensa.
      expect(points[3].speed, inInclusiveRange(400, 700));
      expect(points.every((p) => p.speed != null), isTrue);
    },
  );

  test('a track with no flight to go by is cut at the long silences', () {
    final points = OpenSkySource.parsePath(_track['path']);
    final leg = OpenSkySource.legAround(points, DateTime.utc(2026, 11, 13, 9));

    expect(points, hasLength(12));
    expect(leg, hasLength(11));
    expect(
      OpenSkySource.legAround(
        points,
        DateTime.utc(2026, 11, 13, 12),
      ).single.latitude,
      50.0006,
    );
    expect(OpenSkySource.legAround(const [], DateTime.utc(2026)), isEmpty);
    expect(OpenSkySource.parsePath(null), isEmpty);
  });

  test('a flight too recent to be listed is found by its track', () async {
    // The nightly batch hasn't listed it yet (404, empty list), but the
    // logbook says when it flew.
    final start = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final end = start.add(const Duration(hours: 1));
    int s(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/api/flights/aircraft') {
        return _json(<Object>[], 404);
      }
      expect(request.url.queryParameters['time'], '${s(start) + 1800}');
      return _json({
        'icao24': '3c6743',
        'callsign': 'DLH2EF  ',
        'path': [
          [s(start), 45.6, 8.7, 300, 349, false],
          [s(start) + 900, 46.6, 8.9, 8800, 354, false],
          [s(start) + 1800, 47.9, 9.0, 8800, 354, false],
          [s(start) + 2700, 49.2, 9.1, 5000, 354, false],
          [s(end), 50.0, 8.5, 300, 249, false],
          // What it did next, an hour and a half later.
          [s(end) + 5400, 50.0, 8.5, 300, 70, false],
        ],
      });
    });

    final flights = await OpenSkySource().flightsOfAircraft(
      client,
      '3c6743',
      AdsbWindow.forDay(start, expectedStart: start, expectedEnd: end),
    );

    expect(paths, ['/api/flights/aircraft', '/api/tracks/all']);
    expect(flights.single.callsign, 'DLH2EF');
    expect(flights.single.points, hasLength(5));
    expect(flights.single.end.difference(flights.single.start).inMinutes, 60);
  });

  test('an old day without flights costs no second request', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return _json(<Object>[], 404);
    });

    final flights = await OpenSkySource().flightsOfAircraft(
      client,
      '3c6743',
      AdsbWindow.forDay(
        _day.subtract(const Duration(days: 300)),
        expectedStart: _day.subtract(const Duration(days: 300, hours: -8)),
        expectedEnd: _day.subtract(const Duration(days: 300, hours: -9)),
      ),
    );

    expect(flights, isEmpty);
    expect(requests, 1);
  });

  group('by callsign', () {
    test('looks among the departures of the flight\'s airport', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return _json(_flights);
      });

      final flights = await OpenSkySource().flightsOfCallsign(
        client,
        'dlh 2ef',
        AdsbWindow.forDay(_day),
        departureIcao: 'limc',
        arrivalIcao: 'EDDF',
      );

      expect(requests.single.path, '/api/flights/departure');
      expect(requests.single.queryParameters['airport'], 'LIMC');
      expect(flights.single.callsign, 'DLH2EF');
    });

    test('a callsign nobody flew falls back to the departures for the '
        'arrival, and those whose arrival is unknown', () async {
      final client = MockClient((_) async => _json(_flights));
      final flights = await OpenSkySource().flightsOfCallsign(
        client,
        'U23895',
        AdsbWindow.forDay(_day),
        departureIcao: 'LIMC',
        arrivalIcao: 'loww',
      );
      expect([for (final f in flights) f.callsign], ['DLH246']);
      expect(flights.single.byRoute, isTrue);

      // Without the arrival, a callsign search stays a callsign search.
      expect(
        await OpenSkySource().flightsOfCallsign(
          client,
          'U23895',
          AdsbWindow.forDay(_day),
          departureIcao: 'LIMC',
        ),
        isEmpty,
      );
    });

    test('or of its arrivals, and needs one of the two', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return _json(_flights);
      });
      final source = OpenSkySource();

      await source.flightsOfCallsign(
        client,
        'DLH2EF',
        AdsbWindow.forDay(_day),
        arrivalIcao: 'EDDF',
      );
      expect(requests.single.path, '/api/flights/arrival');

      await expectLater(
        source.flightsOfCallsign(client, 'DLH2EF', AdsbWindow.forDay(_day)),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.message,
            'message',
            contains('airport'),
          ),
        ),
      );
    });
  });

  group('signed in', () {
    http.Response token(String value, {int expiresIn = 1800}) => _json({
      'access_token': value,
      'expires_in': expiresIn,
      'token_type': 'Bearer',
    });

    test('asks for a token once and sends it along', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return request.url.host == 'auth.opensky-network.org'
            ? token('abc')
            : _json(_flights);
      });
      final source = OpenSkySource(
        clientId: ' me-api-client ',
        clientSecret: 'secret',
      );

      await source.flightsOfAircraft(client, '3c6743', AdsbWindow.forDay(_day));
      await source.flightsOfAircraft(client, '3c6743', AdsbWindow.forDay(_day));

      final signIn = requests.first;
      expect(signIn.method, 'POST');
      expect(
        signIn.url.toString(),
        'https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token',
      );
      expect(signIn.bodyFields, {
        'grant_type': 'client_credentials',
        'client_id': 'me-api-client',
        'client_secret': 'secret',
      });
      expect(
        requests.where((r) => r.url.host == 'auth.opensky-network.org'),
        hasLength(1),
      );
      expect(requests.last.headers['Authorization'], 'Bearer abc');
    });

    test('a token that ran out is renewed once', () async {
      var tokens = 0;
      final sent = <String?>[];
      final client = MockClient((request) async {
        if (request.url.host == 'auth.opensky-network.org') {
          return token('token${++tokens}');
        }
        sent.add(request.headers['Authorization']);
        return sent.length == 1 ? http.Response('', 401) : _json(_flights);
      });

      final flights = await OpenSkySource(
        clientId: 'id',
        clientSecret: 'secret',
      ).flightsOfAircraft(client, '3c6743', AdsbWindow.forDay(_day));

      expect(flights, hasLength(3));
      expect(sent, ['Bearer token1', 'Bearer token2']);
    });

    test(
      'credentials OpenSky turns down are a matter for the settings',
      () async {
        // The real answer to a wrong client.
        final client = MockClient(
          (_) async => _json({
            'error': 'invalid_client',
            'error_description': 'Invalid client or Invalid client credentials',
          }, 401),
        );

        await expectLater(
          OpenSkySource(
            clientId: 'id',
            clientSecret: 'nope',
          ).flightsOfAircraft(client, '3c6743', AdsbWindow.forDay(_day)),
          throwsA(
            isA<AdsbException>().having(
              (e) => e.needsSetup,
              'needsSetup',
              isTrue,
            ),
          ),
        );
        await expectLater(
          OpenSkySource.requestToken(client, 'id', 'nope'),
          throwsA(isA<AdsbException>()),
        );
      },
    );
  });

  test('a used up allowance says when to come back', () async {
    final client = MockClient(
      (_) async => http.Response(
        'Too many requests',
        429,
        headers: {'x-rate-limit-retry-after-seconds': '30000'},
      ),
    );
    Future<String> message(OpenSkySource source) async {
      try {
        await source.track(
          client,
          AdsbFlight(
            provider: AdsbProvider.openSky,
            icao24: '3c6743',
            start: _day,
            end: _day.add(const Duration(hours: 1)),
          ),
        );
      } on AdsbException catch (e) {
        return e.message;
      }
      fail('should have thrown');
    }

    expect(
      await message(OpenSkySource()),
      allOf(contains('anonymous'), contains('about 9 h')),
    );
  });

  test('a flight OpenSky has no track of says so', () async {
    final client = MockClient((_) async => http.Response('', 404));
    await expectLater(
      OpenSkySource().track(
        client,
        AdsbFlight(
          provider: AdsbProvider.openSky,
          icao24: '3c6743',
          start: _day,
          end: _day.add(const Duration(hours: 1)),
        ),
      ),
      throwsA(
        isA<AdsbException>().having(
          (e) => e.message,
          'message',
          contains('30 days'),
        ),
      ),
    );
  });

  test('the credentials file OpenSky hands out can be pasted whole', () {
    final credentials = OpenSkyCredentials.fromJson(
      '{"clientId": "me-api-client", "clientSecret": "s3cret"}',
    );
    expect(credentials?.clientId, 'me-api-client');
    expect(credentials?.clientSecret, 's3cret');
    expect(OpenSkyCredentials.fromJson('me-api-client'), isNull);
    expect(OpenSkyCredentials.fromJson('{"clientId": "only"}'), isNull);
  });

  group('AdsbWindow', () {
    test('is the UTC day', () {
      final window = AdsbWindow.forDay(DateTime(2026, 11, 13, 17, 30));
      expect(window.from, DateTime.utc(2026, 11, 13));
      expect(window.to, DateTime.utc(2026, 11, 14));
      expect(window.utcDays, [DateTime.utc(2026, 11, 13)]);
    });

    test('stretches over a logged flight that runs past midnight', () {
      final window = AdsbWindow.forDay(
        _day,
        expectedStart: DateTime.utc(2026, 11, 13, 23),
        expectedEnd: DateTime.utc(2026, 11, 14, 1, 30),
      );
      expect(window.from, _day);
      expect(window.to, DateTime.utc(2026, 11, 14, 1, 30));
      expect(window.utcDays, [_day, DateTime.utc(2026, 11, 14)]);
      expect(window.expectedStart, DateTime.utc(2026, 11, 13, 23));
    });

    test('ignores logged times of another day', () {
      final window = AdsbWindow.forDay(
        DateTime.utc(2026, 11, 20),
        expectedStart: DateTime.utc(2026, 11, 13, 23),
        expectedEnd: DateTime.utc(2026, 11, 14, 1, 30),
      );
      expect(window.from, DateTime.utc(2026, 11, 20));
      expect(window.to, DateTime.utc(2026, 11, 21));
      expect(window.expectedStart, isNull);
    });
  });
}
