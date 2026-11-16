import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/services/adsb_track_service.dart';
import 'package:zenith/services/adsb_track_source.dart';
import 'package:zenith/services/aircraft_hex_resolver.dart';
import 'package:zenith/services/callsign_route_lookup.dart';

final _day = DateTime.utc(2026, 11, 13);
final _window = AdsbWindow.forDay(_day);

AdsbFlight _flight(
  AdsbProvider provider,
  int hour, {
  String hex = '4ca242',
  List<TrackPoint>? points,
}) => AdsbFlight(
  provider: provider,
  icao24: hex,
  start: _day.add(Duration(hours: hour)),
  end: _day.add(Duration(hours: hour + 1)),
  points: points,
);

TrackPoint _point(int second, {double? altitude, bool onGround = false}) =>
    TrackPoint(
      time: _day.add(Duration(hours: 8, seconds: second)),
      latitude: 45 + second / 1000,
      longitude: 9,
      altitude: altitude,
      onGround: onGround,
    );

/// A provider that answers from a table.
class _FakeSource extends AdsbTrackSource {
  _FakeSource(this.provider, {this.byHex = const {}, this.error, this.points});

  @override
  final AdsbProvider provider;
  final Map<String, List<AdsbFlight>> byHex;
  final Object? error;
  final List<TrackPoint>? points;
  final asked = <String>[];

  @override
  Future<List<AdsbFlight>> flightsOfAircraft(
    http.Client client,
    String icao24,
    AdsbWindow window,
  ) async {
    asked.add(icao24);
    if (error != null) throw error!;
    return byHex[icao24] ?? const [];
  }

  @override
  Future<List<AdsbFlight>> flightsOfCallsign(
    http.Client client,
    String callsign,
    AdsbWindow window, {
    String? departureIcao,
    String? arrivalIcao,
  }) async {
    asked.add('$callsign $departureIcao-$arrivalIcao');
    if (error != null) throw error!;
    return byHex.values.expand((f) => f).toList();
  }

  @override
  Future<List<TrackPoint>> track(http.Client client, AdsbFlight flight) async {
    return flight.points ?? points ?? const [];
  }
}

class _FakeHexSource extends HexSource {
  const _FakeHexSource(this.hexes, {this.fails = false});
  final List<String> hexes;
  final bool fails;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<List<String>> hexesFor(http.Client client, String registration) async {
    if (fails) throw http.ClientException('offline');
    return hexes;
  }
}

AdsbTrackService _service(
  List<AdsbTrackSource> sources, {
  List<HexSource> hexSources = const [
    _FakeHexSource(['4ca242']),
  ],
}) => AdsbTrackService(
  sources: sources,
  resolver: AircraftHexResolver(hexSources),
  httpClient: MockClient((_) async => fail('no request expected')),
);

AdsbFlight _byRoute(String callsign, int hour, {String? arrival}) => AdsbFlight(
  provider: AdsbProvider.flyItalyAdsb,
  icao24: '4ca242',
  start: _day.add(Duration(hours: hour)),
  end: _day.add(Duration(hours: hour + 3)),
  callsign: callsign,
  departure: 'LIMC',
  arrival: arrival,
  byRoute: true,
);

void main() {
  group('flights found by route', () {
    final asked = <String>[];
    AdsbTrackService service(
      List<AdsbFlight> flights,
      Map<String, CallsignRoute?> routes, {
      Set<String> failing = const {},
    }) => AdsbTrackService(
      sources: [
        _FakeSource(AdsbProvider.flyItalyAdsb, byHex: {'any': flights}),
      ],
      resolver: const AircraftHexResolver([]),
      httpClient: MockClient((_) async => fail('no request expected')),
      routeOf: (client, callsign) async {
        asked.add(callsign);
        if (failing.contains(callsign)) throw http.ClientException('down');
        return routes[callsign];
      },
    );

    setUp(asked.clear);

    test('keep only those sure to have gone to the arrival', () async {
      final result =
          await service(
            [
              _byRoute('NOS7082', 5, arrival: 'HEMA'),
              _byRoute('EJU54JF', 15),
              _byRoute('EJU87DN', 7),
              _byRoute('XYZ1', 9),
            ],
            {
              'EJU54JF': const CallsignRoute(
                origin: 'LIMC',
                destination: 'HEMA',
              ),
              'EJU87DN': const CallsignRoute(
                origin: 'LIMC',
                destination: 'GCTS',
              ),
            },
          ).searchCallsign(
            'U23895',
            _window,
            departureIcao: 'LIMC',
            arrivalIcao: 'hema',
          );

      expect(
        [for (final f in result.flights) f.callsign],
        ['NOS7082', 'EJU54JF'],
      );
      final confirmed = result.flights.last;
      expect(confirmed.arrival, 'HEMA');
      expect(confirmed.arrivalUnseen, isTrue);
      expect(result.flights.first.arrivalUnseen, isFalse);
      // Only the landings nobody saw are looked up.
      expect(asked, unorderedEquals(['EJU54JF', 'EJU87DN', 'XYZ1']));
    });

    test('offer the unknown ones when none is sure', () async {
      final result =
          await service(
            [_byRoute('EJU54JF', 15), _byRoute('EJU87DN', 7)],
            {
              'EJU87DN': const CallsignRoute(
                origin: 'LIMC',
                destination: 'GCTS',
              ),
            },
          ).searchCallsign(
            'U23895',
            _window,
            departureIcao: 'LIMC',
            arrivalIcao: 'HEMA',
          );
      expect([for (final f in result.flights) f.callsign], ['EJU54JF']);
      expect(result.flights.single.arrival, isNull);
    });

    test('remember routes, but not failed lookups', () async {
      final search = service(
        [_byRoute('EJU54JF', 15), _byRoute('EJU87DN', 7)],
        {'EJU87DN': const CallsignRoute(origin: 'LIMC', destination: 'GCTS')},
        failing: {'EJU54JF'},
      );
      Future<void> once() => search.searchCallsign(
        'U23895',
        _window,
        departureIcao: 'LIMC',
        arrivalIcao: 'HEMA',
      );
      await once();
      await once();
      expect(asked.where((c) => c == 'EJU87DN'), hasLength(1));
      expect(asked.where((c) => c == 'EJU54JF'), hasLength(2));
    });
  });

  test('adsbdb routes are read from their answer', () {
    final route = parseAdsbdbRoute({
      'response': {
        'flightroute': {
          'callsign': 'EJU54JF',
          'origin': {'icao_code': 'LIMC', 'iata_code': 'MXP'},
          'destination': {'icao_code': 'HEMA', 'iata_code': 'RMF'},
        },
      },
    });
    expect(route?.origin, 'LIMC');
    expect(route?.destination, 'HEMA');
    expect(parseAdsbdbRoute({'response': 'unknown callsign'}), isNull);
  });

  test(
    'a registration is searched under its address on every provider',
    () async {
      final fly = _FakeSource(
        AdsbProvider.flyItalyAdsb,
        byHex: {
          '4ca242': [_flight(AdsbProvider.flyItalyAdsb, 10)],
        },
      );
      final sky = _FakeSource(
        AdsbProvider.openSky,
        byHex: {
          '4ca242': [
            _flight(AdsbProvider.openSky, 6),
            _flight(AdsbProvider.openSky, 14),
          ],
        },
      );

      final result = await _service([
        fly,
        sky,
      ]).searchRegistration('EI-DCL', _window);

      expect(fly.asked, ['4ca242']);
      expect(sky.asked, ['4ca242']);
      expect(result.hexes.single.hex, '4ca242');
      // Oldest first, whoever saw them.
      expect(result.flights.map((f) => f.start.hour), [6, 10, 14]);
      expect(result.problems, isEmpty);
    },
  );

  test('a provider that fails does not spoil what the other found', () async {
    final result = await _service([
      _FakeSource(
        AdsbProvider.flyItalyAdsb,
        error: const AdsbException(
          'FlyItalyADSB needs an API key.',
          needsSetup: true,
        ),
      ),
      _FakeSource(
        AdsbProvider.openSky,
        byHex: {
          '4ca242': [_flight(AdsbProvider.openSky, 6)],
        },
      ),
    ]).searchRegistration('EI-DCL', _window);

    expect(result.flights, hasLength(1));
    expect(result.problems.keys, [AdsbProvider.flyItalyAdsb]);
    expect(result.problems.values.single.needsSetup, isTrue);
  });

  test(
    'something unreadable from a provider is a problem, not a crash',
    () async {
      final result = await _service([
        _FakeSource(AdsbProvider.openSky, error: const FormatException('bad')),
      ]).searchRegistration('EI-DCL', _window);

      expect(result.flights, isEmpty);
      expect(
        result.problems[AdsbProvider.openSky]!.message,
        contains('OpenSky Network'),
      );
    },
  );

  test('when the sources disagree, each address is tried in turn', () async {
    final sky = _FakeSource(
      AdsbProvider.openSky,
      byHex: {
        '4ca999': [_flight(AdsbProvider.openSky, 6, hex: '4ca999')],
      },
    );

    final result = await _service(
      [sky],
      hexSources: const [
        _FakeHexSource(['4ca242', '4ca999']),
      ],
    ).searchRegistration('EI-DCL', _window);

    expect(sky.asked, ['4ca242', '4ca999']);
    expect(result.flights.single.icao24, '4ca999');
  });

  test('a registration nobody knows the address of says so', () async {
    await expectLater(
      _service(
        [_FakeSource(AdsbProvider.openSky)],
        hexSources: const [_FakeHexSource([])],
      ).searchRegistration('zz-nope', _window),
      throwsA(
        isA<AdsbException>().having(
          (e) => e.message,
          'message',
          'No ICAO address found for "ZZ-NOPE".',
        ),
      ),
    );
    await expectLater(
      _service(
        [_FakeSource(AdsbProvider.openSky)],
        hexSources: const [_FakeHexSource([], fails: true)],
      ).searchRegistration('ZZ-NOPE', _window),
      throwsA(
        isA<AdsbException>().having(
          (e) => e.message,
          'message',
          contains('Could not ask: Fake'),
        ),
      ),
    );
  });

  test('nothing switched on is a matter for the settings', () async {
    expect(
      () => _service([]).searchRegistration('EI-DCL', _window),
      throwsA(
        isA<AdsbException>().having((e) => e.needsSetup, 'needsSetup', isTrue),
      ),
    );
    await expectLater(
      _service([
        _FakeSource(AdsbProvider.openSky),
      ], hexSources: const []).searchRegistration('EI-DCL', _window),
      throwsA(
        isA<AdsbException>().having((e) => e.needsSetup, 'needsSetup', isTrue),
      ),
    );
  });

  test('an address is searched as it is, when it is one', () async {
    final sky = _FakeSource(AdsbProvider.openSky);
    final service = _service([sky], hexSources: const []);

    await service.searchHex(' 4CA242 ', _window);
    expect(sky.asked, ['4ca242']);

    expect(
      () => service.searchHex('EI-DCL', _window),
      throwsA(isA<AdsbException>()),
    );
  });

  test(
    'a callsign goes to the providers with the airports of the flight',
    () async {
      final sky = _FakeSource(
        AdsbProvider.openSky,
        byHex: {
          'x': [_flight(AdsbProvider.openSky, 6)],
        },
      );

      final result = await _service([sky]).searchCallsign(
        'RYR4WY',
        _window,
        departureIcao: 'LIMC',
        arrivalIcao: 'EDDF',
      );

      expect(sky.asked, ['RYR4WY LIMC-EDDF']);
      expect(result.flights, hasLength(1));
      expect(result.hexes, isEmpty);
    },
  );

  group('loadTrack', () {
    test('gives a track ready to be stored', () async {
      final service = _service([_FakeSource(AdsbProvider.openSky)]);
      final flight = _flight(
        AdsbProvider.openSky,
        8,
        points: [
          _point(40, altitude: 500),
          _point(0, onGround: true),
          _point(20, altitude: 300),
          _point(60, onGround: true),
        ],
      );

      final points = await service.loadTrack(
        flight,
        departureElevation: 100,
        arrivalElevation: 80,
      );

      // In order, every point with an altitude and a speed.
      expect(points.map((p) => p.altitude), [100, 300, 500, 80]);
      expect(points.every((p) => p.speed != null), isTrue);
    });

    test('a track with no positions is refused', () async {
      final service = _service([
        _FakeSource(AdsbProvider.openSky, points: [_point(0, altitude: 1)]),
      ]);
      await expectLater(
        service.loadTrack(_flight(AdsbProvider.openSky, 8)),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.message,
            'message',
            contains('no positions'),
          ),
        ),
      );
    });

    test('a flight of a provider switched off since is refused', () async {
      final service = _service([_FakeSource(AdsbProvider.openSky)]);
      expect(
        () => service.loadTrack(_flight(AdsbProvider.flyItalyAdsb, 8)),
        throwsA(
          isA<AdsbException>().having(
            (e) => e.needsSetup,
            'needsSetup',
            isTrue,
          ),
        ),
      );
    });
  });
}
