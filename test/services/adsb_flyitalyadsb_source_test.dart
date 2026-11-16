import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/services/adsb_flyitalyadsb_source.dart';
import 'package:zenith/services/adsb_track_source.dart';

/// Midnight UTC of 13 November 2026.
const _midnight = 1794528000;
final _day = DateTime.utc(2026, 11, 13);

/// A day of an aircraft as readsb writes it (`trace_full`): each row is
/// `[seconds after timestamp, lat, lon, altitude ft | "ground", ground speed
/// kt, track, flags, vertical rate, aircraft details, source, geometric
/// altitude ft, ...]`. Flag 2 marks the start of a new leg.
Map<String, Object?> _trace({int timestamp = _midnight}) => {
  'icao': '4ca242',
  'r': 'EI-DCL',
  't': 'B738',
  'timestamp': timestamp.toDouble(),
  'trace': [
    // A flight from 06:00 to 07:00.
    [
      21600.0,
      45.63,
      8.72,
      'ground',
      12.0,
      349.0,
      2,
      null,
      {'flight': 'RYR4WY  '},
      'adsb_icao',
      null,
      null,
      null,
      null,
    ],
    [
      21660.4,
      45.65,
      8.73,
      1000,
      150.0,
      350.0,
      0,
      1800,
      null,
      'adsb_icao',
      1200,
      1800,
      null,
      null,
    ],
    [
      23000.0,
      46.2,
      8.9,
      20000,
      420.0,
      354.0,
      0,
      0,
      null,
      'adsb_icao',
      20600,
      0,
      null,
      null,
    ],
    [
      25200.0,
      50.03,
      8.57,
      'ground',
      20.0,
      249.0,
      0,
      null,
      null,
      'adsb_icao',
      null,
      null,
      null,
      null,
    ],
    // The next one, from 09:00.
    [
      32400.0,
      50.03,
      8.57,
      'ground',
      10.0,
      70.0,
      2,
      null,
      {'flight': 'RYR5XZ'},
      'adsb_icao',
      null,
      null,
      null,
      null,
    ],
    [
      32500.0,
      50.05,
      8.6,
      1500,
      160.0,
      70.0,
      0,
      2000,
      null,
      'adsb_icao',
      1700,
      2000,
      null,
      null,
    ],
    [
      33000.0,
      50.2,
      8.9,
      9000,
      300.0,
      70.0,
      0,
      1500,
      null,
      'adsb_icao',
      9300,
      1500,
      null,
      null,
    ],
    // Towed across the apron in the evening: no flight.
    [
      72000.0,
      51.0,
      9.0,
      'ground',
      3.0,
      10.0,
      2,
      null,
      null,
      'adsb_icao',
      null,
      null,
      null,
      null,
    ],
    [
      72100.0,
      51.001,
      9.0,
      'ground',
      3.0,
      10.0,
      0,
      null,
      null,
      'adsb_icao',
      null,
      null,
      null,
      null,
    ],
  ],
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  final window = AdsbWindow.forDay(_day);

  test(
    'a day is cut into its flights, in the units tracks are stored in',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return _json(_trace());
      });
      final source = FlyItalyAdsbSource(
        apiKey: ' my-key ',
        userAgent: 'Zenith/1',
      );

      final flights = await source.flightsOfAircraft(client, '4ca242', window);

      expect(
        requests.single.url.toString(),
        'https://api.flyitalyadsb.com/v2/history/4ca242/2026-11-13',
      );
      expect(requests.single.headers['X-Api-Key'], 'my-key');
      expect(requests.single.headers['User-Agent'], 'Zenith/1');

      // The tow is no flight.
      expect(flights, hasLength(2));
      final first = flights.first;
      expect(first.provider, AdsbProvider.flyItalyAdsb);
      expect(first.callsign, 'RYR4WY');
      expect(first.start, DateTime.utc(2026, 11, 13, 6));
      expect(first.end, DateTime.utc(2026, 11, 13, 7));
      expect(flights.last.callsign, 'RYR5XZ');

      final points = first.points!;
      expect(points, hasLength(4));
      // On the ground there is no altitude: it is filled in later.
      expect(points.first.onGround, isTrue);
      expect(points.first.altitude, isNull);
      // Geometric altitude, feet → metres; knots → km/h.
      expect(points[1].altitude, closeTo(1200 * 0.3048, 0.01));
      expect(points[1].speed, closeTo(150 * 1.852, 0.01));
      expect(points[1].heading, 350);
      expect(points[1].time, DateTime.utc(2026, 11, 13, 6, 1, 0, 400));
      // The track source hands its points over without asking again.
      expect(await source.track(client, first), same(points));
      expect(requests, hasLength(1));
    },
  );

  test('barometric altitude is used when the trace has no geometric one', () {
    final rows = FlyItalyAdsbSource.parseTrace({
      'timestamp': _midnight,
      'trace': [
        [0, 45.0, 9.0, 2000, 100, 90, 0, 0, null, 'mlat'],
        [10, 45.1, 9.0, 3000, 100, 90, 0, 0, null, 'mlat'],
        // Flag 8: this altitude is geometric.
        [20, 45.2, 9.0, 4000, 100, 90, 8, 0, null, 'adsb_icao'],
        ['junk'],
      ],
    });

    expect(rows, hasLength(3));
    expect(rows[0].point.altitude, closeTo(2000 * 0.3048, 0.01));
    expect(rows[2].point.altitude, closeTo(4000 * 0.3048, 0.01));
    expect(FlyItalyAdsbSource.parseTrace({'trace': <Object>[]}), isEmpty);
  });

  test('a flight over midnight UTC is put together from both days', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('2026-11-13')) {
        return _json({
          'timestamp': _midnight,
          'trace': [
            [84600.0, 45.0, 9.0, 'ground', 10, 90, 2, null, null, 'adsb_icao'],
            [85000.0, 45.2, 9.5, 20000, 400, 90, 0, 0, null, 'adsb_icao'],
          ],
        });
      }
      return _json({
        'timestamp': _midnight + 86400,
        'trace': [
          [600.0, 46.0, 12.0, 20000, 400, 90, 0, 0, null, 'adsb_icao'],
          [3000.0, 47.0, 15.0, 'ground', 10, 90, 0, null, null, 'adsb_icao'],
        ],
      });
    });

    final flights = await FlyItalyAdsbSource(apiKey: 'k').flightsOfAircraft(
      client,
      '4ca242',
      AdsbWindow.forDay(
        _day,
        expectedStart: DateTime.utc(2026, 11, 13, 23, 30),
        expectedEnd: DateTime.utc(2026, 11, 14, 0, 50),
      ),
    );

    expect(paths, [
      '/v2/history/4ca242/2026-11-13',
      '/v2/history/4ca242/2026-11-14',
    ]);
    expect(flights.single.points, hasLength(4));
    expect(flights.single.end, DateTime.utc(2026, 11, 14, 0, 50));
  });

  group('splitLegs', () {
    TraceRow row(
      int minute, {
      bool newLeg = false,
      bool ground = false,
      String? callsign,
    }) => TraceRow(
      TrackPoint(
        time: _day.add(Duration(minutes: minute)),
        latitude: 45,
        longitude: 9,
        altitude: ground ? null : 3000,
        onGround: ground,
      ),
      newLeg: newLeg,
      callsign: callsign,
    );

    test('a flight cut by a stretch out of coverage is one flight', () {
      final legs = FlyItalyAdsbSource.splitLegs([
        row(0, newLeg: true, ground: true, callsign: 'UAL85'),
        row(10),
        row(34),
        // 25 minutes unheard, in the air on both sides.
        row(59, newLeg: true, callsign: 'UAL85'),
        row(600, ground: true),
      ]);
      expect(legs, hasLength(1));
      expect(legs.single, hasLength(5));
    });

    test('a landing in between, or another callsign, is another flight', () {
      final afterLanding = FlyItalyAdsbSource.splitLegs([
        row(0, newLeg: true, ground: true),
        row(30),
        row(60, ground: true),
        row(90, newLeg: true, ground: true),
        row(100),
      ]);
      expect(afterLanding, hasLength(2));

      final renamed = FlyItalyAdsbSource.splitLegs([
        row(0, newLeg: true, ground: true, callsign: 'ABC1'),
        row(30),
        row(40, newLeg: true, callsign: 'ABC2'),
        row(50),
      ]);
      expect(renamed, hasLength(2));

      final tooLong = FlyItalyAdsbSource.splitLegs([
        row(0, newLeg: true, ground: true),
        row(30),
        row(200, newLeg: true),
        row(210),
      ]);
      expect(tooLong, hasLength(2));
    });
  });

  test('a day without a trace has no flights', () async {
    final client = MockClient((_) async => _json({'error': 'no trace'}, 404));
    final flights = await FlyItalyAdsbSource(
      apiKey: 'k',
    ).flightsOfAircraft(client, '4ca242', window);
    expect(flights, isEmpty);
  });

  test('without a key nothing is asked', () async {
    final client = MockClient((_) async => fail('must not be asked'));
    for (final key in [null, '', '  ']) {
      await expectLater(
        FlyItalyAdsbSource(
          apiKey: key,
        ).flightsOfAircraft(client, '4ca242', window),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.needsSetup,
            'needsSetup',
            isTrue,
          ),
        ),
      );
    }
  });

  test('errors are told in words the user can act on', () async {
    Future<AdsbException> failure(http.Response response) async {
      try {
        await FlyItalyAdsbSource(apiKey: 'k').flightsOfAircraft(
          MockClient((_) async => response),
          '4ca242',
          window,
        );
      } on AdsbException catch (e) {
        return e;
      }
      fail('should have thrown');
    }

    // The real answer to a wrong key.
    final unauthorized = await failure(
      _json({
        'error': 'missing or invalid X-Api-Key',
        'help': 'https://flyitalyadsb.com/faq/#errore-401',
      }, 401),
    );
    expect(unauthorized.needsSetup, isTrue);
    expect(unauthorized.message, contains('API key'));

    // Whatever else they refuse, they say why.
    final refused = await failure(
      _json({
        'error': 'history beyond the 7 days of the Free plan',
        'code': 'history-depth',
      }, 403),
    );
    expect(
      refused.message,
      'FlyItalyADSB: history beyond the 7 days of the Free plan',
    );
    expect(refused.needsSetup, isFalse);

    // Not JSON at all (a proxy's error page).
    final page = await failure(http.Response('<html>Blocked</html>', 403));
    expect(page.message, contains('HTTP 403'));

    expect(
      (await failure(_json({'error': 'slow down'}, 429))).message,
      contains('slow down'),
    );

    final offline = await FlyItalyAdsbSource(apiKey: 'k')
        .flightsOfAircraft(
          MockClient((_) async => throw http.ClientException('offline')),
          '4ca242',
          window,
        )
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(
      offline,
      isA<AdsbException>().having(
        (e) => e.message,
        'message',
        contains('connection'),
      ),
    );
  });

  group('by flight number', () {
    /// The window is yesterday, whenever the test runs: the list of a
    /// callsign's flights only goes up to yesterday.
    final now = DateTime.now().toUtc();
    final yesterday = DateTime.utc(now.year, now.month, now.day - 1);
    int at(int hour, [int minute = 0]) =>
        yesterday
            .add(Duration(hours: hour, minutes: minute))
            .millisecondsSinceEpoch ~/
        1000;

    test('finds the flights of that day and fetches their track', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.startsWith('/v2/flights/callsign/')) {
          return _json({
            'callsign': 'RYR4WY',
            'count': 2,
            'flights': [
              {
                'icao': '4CA242',
                'r': 'EI-DCL',
                'callsign': 'RYR4WY',
                'from': {'airport': 'LIMC', 'time': at(6)},
                'to': {'airport': 'EDDF', 'time': at(7)},
                'first_seen': at(6),
                'last_seen': at(7),
              },
              // The same flight number, three days earlier.
              {
                'icao': '4ca999',
                'callsign': 'RYR4WY',
                'from': null,
                'to': null,
                'first_seen': at(6) - 3 * 86400,
                'last_seen': at(7) - 3 * 86400,
              },
            ],
          });
        }
        return _json(_trace(timestamp: at(0)));
      });
      final source = FlyItalyAdsbSource(apiKey: 'k');

      final flights = await source.flightsOfCallsign(
        client,
        'ryr 4wy',
        AdsbWindow.forDay(yesterday),
      );

      expect(requests.single.path, '/v2/flights/callsign/RYR4WY');
      expect(requests.single.queryParameters, {'days': '1'});
      final flight = flights.single;
      expect(flight.icao24, '4ca242');
      expect(flight.departure, 'LIMC');
      expect(flight.arrival, 'EDDF');
      expect(flight.points, isNull);

      // Its track is that stretch of the aircraft's day, not the next leg.
      final points = await source.track(client, flight);
      expect(requests.last.path, startsWith('/v2/history/4ca242/'));
      expect(points, hasLength(4));
      expect(points.last.time, yesterday.add(const Duration(hours: 7)));
    });

    group('by route', () {
      String date(DateTime day) =>
          '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
          '${'${day.day}'.padLeft(2, '0')}';
      Map<String, Object?> observed(
        String hex,
        String callsign,
        int start,
        String? to,
      ) => {
        'icao': hex,
        'callsign': callsign,
        'from': {'airport': 'LIMC', 'time': start},
        'to': to == null ? null : {'airport': to, 'time': start + 9000},
        'first_seen': start,
        'last_seen': start + 9000,
      };

      MockClient client(List<Uri> requests) => MockClient((request) async {
        requests.add(request.url);
        final path = request.url.path;
        if (path.startsWith('/v2/flights/callsign/')) {
          // easyJet flies alphanumeric callsigns: U23895 was never heard.
          return _json({
            'callsign': 'U23895',
            'count': 0,
            'tried': ['U23895', 'EZY3895'],
            'flights': <Object>[],
          });
        }
        if (path == '/v2/flights/airport/LIMC') {
          return _json({
            'count': 4,
            'flights': [
              observed('aaaaaa', 'NOS7082', at(5, 12), 'HEMA'),
              observed('bbbbbb', 'EZY52NU', at(9), 'EGKK'),
              // Landed out of the network's reach.
              observed('cccccc', 'EJU54JF', at(15, 54), null),
              observed('dddddd', 'EJU87DN', at(7, 51), 'GCTS'),
            ],
          });
        }
        fail('unexpected request $path');
      });

      test('a flight number nobody flew is looked for among the departures '
          'for the arrival, and those whose landing nobody saw', () async {
        final requests = <Uri>[];
        final flights = await FlyItalyAdsbSource(apiKey: 'k').flightsOfCallsign(
          client(requests),
          'U23895',
          AdsbWindow.forDay(yesterday),
          departureIcao: 'limc',
          arrivalIcao: 'hema',
        );

        expect(requests.last.queryParameters, {
          'type': 'departures',
          'date': date(yesterday),
        });
        expect([for (final f in flights) f.callsign], ['NOS7082', 'EJU54JF']);
        expect(flights.every((f) => f.byRoute), isTrue);
        expect(flights.last.arrival, isNull);
      });

      test('with one airport, the flights of the airline FlyItaly read the '
          'flight number as', () async {
        final flights = await FlyItalyAdsbSource(apiKey: 'k').flightsOfCallsign(
          client([]),
          'U23895',
          AdsbWindow.forDay(yesterday),
          departureIcao: 'LIMC',
        );
        expect([for (final f in flights) f.callsign], ['EZY52NU']);
      });

      test('without airports, nothing more is asked', () async {
        final requests = <Uri>[];
        final flights = await FlyItalyAdsbSource(apiKey: 'k').flightsOfCallsign(
          client(requests),
          'U23895',
          AdsbWindow.forDay(yesterday),
        );
        expect(flights, isEmpty);
        expect(requests, hasLength(1));
      });

      test('airline codes come from the forms tried', () {
        expect(
          FlyItalyAdsbSource.airlinePrefixes(['U23895', 'EZY3895', 'ezy 12']),
          {'EZY'},
        );
      });
    });

    test("says so when the day can't be searched", () async {
      final client = MockClient((_) async => fail('must not be asked'));
      final source = FlyItalyAdsbSource(apiKey: 'k');

      await expectLater(
        source.flightsOfCallsign(client, 'RYR4WY', AdsbWindow.forDay(now)),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.message,
            'message',
            contains('registration'),
          ),
        ),
      );
      await expectLater(
        source.flightsOfCallsign(
          client,
          'RYR4WY',
          AdsbWindow.forDay(now.subtract(const Duration(days: 20))),
        ),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.message,
            'message',
            contains('14 days'),
          ),
        ),
      );
    });
  });

  test('checkKey tells a refused key from an accepted one', () async {
    expect(
      await FlyItalyAdsbSource.checkKey(
        MockClient(
          (_) async => _json({'error': 'missing or invalid X-Api-Key'}, 401),
        ),
        'bad',
      ),
      isFalse,
    );
    expect(
      await FlyItalyAdsbSource.checkKey(
        MockClient(
          (_) async =>
              _json({'icao': '000000', 'count': 0, 'dates': <String>[]}),
        ),
        'good',
      ),
      isTrue,
    );
    await expectLater(
      FlyItalyAdsbSource.checkKey(
        MockClient((_) async => throw http.ClientException('offline')),
        'k',
      ),
      throwsA(isA<AdsbException>()),
    );
  });
}
