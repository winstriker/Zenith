import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/services/adsb_flight_importer.dart';
import 'package:zenith/services/adsb_track_source.dart';
import 'package:zenith/services/database.dart';

Airport airport(
  int id,
  String ident, {
  AirportType type = AirportType.smallAirport,
  int? elevationFt,
}) => Airport(
  id: id,
  ident: ident,
  type: type,
  name: ident,
  latitudeDeg: 45,
  longitudeDeg: 9,
  elevationFt: elevationFt,
  continent: 'EU',
  isoCountry: 'IT',
  isoRegion: 'IT-25',
);

AircraftWithStats aircraft(int id, String tail) => AircraftWithStats(
  id: id,
  tailNumber: tail,
  icaoAircraft: 1,
  description: AircraftDescription.landplane,
  modelFullName: 'Cessna 172',
  designator: 'C172',
  manufacturer: 'Cessna',
  engineCount: 1,
  engineType: EngineType.piston,
  wakeTurbolenceCategory: WakeTurbulenceCategory.L,
  wakeTurbolenceGroup: WakeTurbulenceGroup.G,
  userInserted: false,
);

final start = DateTime.utc(2026, 11, 10, 9);

AdsbFlight flight({
  String? departure,
  String? arrival,
  String? callsign,
  String icao24 = '4ca242',
}) => AdsbFlight(
  provider: AdsbProvider.flyItalyAdsb,
  icao24: icao24,
  start: start,
  end: start.add(const Duration(hours: 1)),
  callsign: callsign,
  departure: departure,
  arrival: arrival,
);

final track = [
  TrackPoint(time: start, latitude: 45.6, longitude: 8.7, onGround: true),
  TrackPoint(
    time: start.add(const Duration(minutes: 30)),
    latitude: 45.5,
    longitude: 9.0,
    altitude: 1000,
  ),
  TrackPoint(
    time: start.add(const Duration(hours: 1)),
    latitude: 45.4,
    longitude: 9.3,
    onGround: true,
  ),
];

AdsbFlightImporter importer({
  Map<String, Airport> byCode = const {},
  Map<(double, double), List<AirportWithDistance>> near = const {},
  List<String> local = const [],
  String? online,
  Object? onlineError,
  List<AircraftWithStats> mine = const [],
  List<String>? onlineAsked,
}) => AdsbFlightImporter(
  fetchPoints: (_) async => track,
  airportByCode: (code) async => byCode[code],
  airportsNear: (lat, lon) async => near[(lat, lon)] ?? const [],
  localRegistrations: (_) async => local,
  onlineRegistration: (hex) async {
    onlineAsked?.add(hex);
    if (onlineError != null) throw onlineError;
    return online;
  },
  aircraft: () async => mine,
);

void main() {
  group('airports', () {
    test('takes the route airports when the database has them', () async {
      final draft = await importer(
        byCode: {'LIMC': airport(1, 'LIMC'), 'LIML': airport(2, 'LIML')},
      ).prepare(flight(departure: 'LIMC', arrival: 'LIML'));
      expect(draft.departure?.airport.ident, 'LIMC');
      expect(draft.departure?.origin, ImportedAirportOrigin.route);
      expect(draft.arrival?.airport.ident, 'LIML');
      expect(draft.arrival?.origin, ImportedAirportOrigin.route);
    });

    test('falls back to the airport nearest the ends of the track', () async {
      final draft = await importer(
        byCode: {'LIMC': airport(1, 'LIMC')},
        near: {
          (45.6, 8.7): [AirportWithDistance(airport(3, 'LILN'), 1.2)],
          (45.4, 9.3): [AirportWithDistance(airport(4, 'LIMB'), 0.4)],
        },
        // LIXX isn't in the database.
      ).prepare(flight(departure: 'LIXX'));
      expect(draft.departure?.airport.ident, 'LILN');
      expect(draft.departure?.origin, ImportedAirportOrigin.nearest);
      expect(draft.departure?.distanceKm, 1.2);
      expect(draft.arrival?.airport.ident, 'LIMB');
    });

    test('no guess at an end the track stops short of', () async {
      final nearStart = [AirportWithDistance(airport(3, 'LILN'), 1.2)];
      final nearEnd = [AirportWithDistance(airport(4, 'LIMB'), 0.4)];
      final draft =
          await importer(
            near: {(45.6, 8.7): nearStart, (45.4, 9.3): nearEnd},
          ).prepare(
            // Seen until 12:00, but the track ends at 10:00.
            AdsbFlight(
              provider: AdsbProvider.openSky,
              icao24: '4ca242',
              start: start,
              end: start.add(const Duration(hours: 3)),
            ),
          );
      expect(draft.departure?.airport.ident, 'LILN');
      expect(draft.arrival, isNull);
      // The times are the provider's, not the track's.
      expect(draft.arrivalTime, start.add(const Duration(hours: 3)));
    });

    test('a landing nobody saw leaves the arrival time open', () async {
      final draft =
          await importer(
            byCode: {'LIMC': airport(1, 'LIMC'), 'HEMA': airport(2, 'HEMA')},
          ).prepare(
            AdsbFlight(
              provider: AdsbProvider.flyItalyAdsb,
              icao24: '4ca242',
              start: start,
              end: start.add(const Duration(hours: 3)),
              departure: 'LIMC',
              arrival: 'HEMA',
              byRoute: true,
              arrivalUnseen: true,
            ),
          );
      expect(draft.arrival?.airport.ident, 'HEMA');
      expect(draft.arrival?.origin, ImportedAirportOrigin.usualRoute);
      expect(draft.departure?.origin, ImportedAirportOrigin.route);
      expect(draft.arrivalTime, isNull);
      expect(draft.departureTime, start);
    });

    test('no airport when there is none near', () async {
      final draft = await importer().prepare(flight());
      expect(draft.departure, isNull);
      expect(draft.arrival, isNull);
    });

    test('fills ground altitudes with the airport elevations', () async {
      final draft = await importer(
        byCode: {
          'LIMC': airport(1, 'LIMC', elevationFt: 768),
          'LIML': airport(2, 'LIML', elevationFt: 353),
        },
      ).prepare(flight(departure: 'LIMC', arrival: 'LIML'));
      expect(draft.points.every((p) => p.altitude != null), isTrue);
      expect(draft.points.first.altitude, closeTo(768 * 0.3048, 0.01));
      expect(draft.points[1].altitude, closeTo(1000, 0.01));
      expect(draft.points.last.altitude, closeTo(353 * 0.3048, 0.01));
      expect(draft.departureTime, start);
      expect(draft.arrivalTime, start.add(const Duration(hours: 1)));
    });

    group('pickNearest', () {
      AirportWithDistance at(String ident, AirportType type, double km) =>
          AirportWithDistance(airport(0, ident, type: type), km);

      test('skips closed airports and balloon ports', () {
        final pick = AdsbFlightImporter.pickNearest([
          at('CLOSED', AirportType.closed, 0.1),
          at('BALLOON', AirportType.balloonport, 0.2),
          at('OPEN', AirportType.smallAirport, 3),
        ]);
        expect(pick?.airport.ident, 'OPEN');
      });

      test('prefers an aerodrome to a nearer helipad', () {
        final pick = AdsbFlightImporter.pickNearest([
          at('HELI', AirportType.heliport, 0.5),
          at('FIELD', AirportType.smallAirport, 1.5),
        ]);
        expect(pick?.airport.ident, 'FIELD');
      });

      test('takes a helipad the track ends on, far from aerodromes', () {
        final pick = AdsbFlightImporter.pickNearest([
          at('HELI', AirportType.heliport, 0.1),
          at('FIELD', AirportType.smallAirport, 12),
        ]);
        expect(pick?.airport.ident, 'HELI');
      });

      test('a heliport is better than nothing', () {
        final pick = AdsbFlightImporter.pickNearest([
          at('HELI', AirportType.heliport, 5),
        ]);
        expect(pick?.airport.ident, 'HELI');
      });
    });
  });

  group('aircraft', () {
    final mine = [aircraft(1, 'I-ABCD'), aircraft(2, 'EI-DCL')];

    test('matches the typed registration, whatever the spelling', () async {
      final asked = <String>[];
      final draft = await importer(
        mine: mine,
        onlineAsked: asked,
      ).prepare(flight(), typedRegistration: 'eidcl');
      expect(draft.aircraft?.id, 2);
      expect(draft.registration, 'EI-DCL');
      // Nothing to ask online when the aircraft is known.
      expect(asked, isEmpty);
    });

    test('matches the registry entry for the address', () async {
      final draft = await importer(
        mine: mine,
        local: ['IABCD'],
      ).prepare(flight(callsign: 'RYR4WY'));
      expect(draft.aircraft?.id, 1);
      expect(draft.registration, 'I-ABCD');
    });

    test('matches a registration sent as callsign', () async {
      final draft = await importer(
        mine: mine,
      ).prepare(flight(callsign: 'IABCD'));
      expect(draft.aircraft?.id, 1);
    });

    test('an unknown aircraft gets the online spelling', () async {
      final draft = await importer(
        mine: mine,
        local: ['DEABC'],
        online: 'D-EABC',
      ).prepare(flight());
      expect(draft.aircraft, isNull);
      expect(draft.registration, 'D-EABC');
    });

    test('offline, the typed registration and then the registry', () async {
      final typed = await importer(
        onlineError: Exception('offline'),
        local: ['DEABC'],
      ).prepare(flight(), typedRegistration: 'd-eabc');
      expect(typed.registration, 'D-EABC');

      final registry = await importer(
        onlineError: Exception('offline'),
        local: ['DEABC'],
      ).prepare(flight());
      expect(registry.registration, 'DEABC');
    });

    test('a callsign alone is no registration', () async {
      final draft = await importer().prepare(flight(callsign: 'RYR4WY'));
      expect(draft.registration, isNull);
      expect(draft.aircraft, isNull);
    });

    test('a failing local registry is no reason to fail', () async {
      final draft = await AdsbFlightImporter(
        fetchPoints: (_) async => track,
        airportByCode: (_) async => null,
        airportsNear: (_, _) async => const [],
        localRegistrations: (_) async => throw StateError('no database'),
        onlineRegistration: (_) async => 'EI-DCL',
        aircraft: () async => mine,
      ).prepare(flight());
      expect(draft.aircraft?.id, 2);
    });
  });

  test('a track of fewer than two points is no flight', () async {
    final importer = AdsbFlightImporter(
      fetchPoints: (_) async => [track.first],
      airportByCode: (_) async => null,
      airportsNear: (_, _) async => const [],
      localRegistrations: (_) async => const [],
      onlineRegistration: (_) async => null,
      aircraft: () async => const [],
    );
    expect(importer.prepare(flight()), throwsA(isA<AdsbException>()));
  });
}
