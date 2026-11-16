import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/flight_track.dart';

TrackPoint _point(
  int second, {
  double lat = 45,
  double lon = 9,
  double? altitude,
  double? speed,
  bool onGround = false,
  int millis = 0,
}) => TrackPoint(
  time: DateTime.utc(2026, 11, 13, 8, 0, second, millis),
  latitude: lat,
  longitude: lon,
  altitude: altitude,
  speed: speed,
  onGround: onGround,
);

void main() {
  test('clean sorts, keeps one point per second and drops non-positions', () {
    final cleaned = TrackTools.clean([
      _point(5, altitude: 500),
      _point(1, altitude: 100),
      // Same second as the next one: tracks are stored to the second.
      _point(3, altitude: 300),
      _point(3, altitude: 999, millis: 400),
      _point(4, lat: 0, lon: 0),
      _point(6, lat: 123),
    ]);

    expect(cleaned.map((p) => p.altitude), [100, 300, 500]);
  });

  test('splitAtGaps cuts where nothing was received for too long', () {
    final legs = TrackTools.splitAtGaps([
      _point(0),
      _point(10),
      _point(50),
      _point(55),
    ], const Duration(seconds: 30));

    expect(legs.map((leg) => leg.length), [2, 2]);
    expect(
      TrackTools.splitAtGaps(const [], const Duration(seconds: 1)),
      isEmpty,
    );
  });

  group('fillAltitudes', () {
    test(
      'uses the airports on the ground and the last altitude in between',
      () {
        final filled = TrackTools.fillAltitudes(
          [
            _point(0, onGround: true),
            _point(1, altitude: 300),
            _point(2),
            _point(3, altitude: 280),
            _point(4, onGround: true),
          ],
          departureElevation: 120,
          arrivalElevation: 90,
        );

        expect(filled.map((p) => p.altitude), [120, 300, 300, 280, 90]);
      },
    );

    test('falls back on the nearest known altitude', () {
      final filled = TrackTools.fillAltitudes([
        _point(0, onGround: true),
        _point(1, altitude: 300),
        _point(2, onGround: true),
      ]);

      expect(filled.map((p) => p.altitude), [300, 300, 300]);
    });

    test('nothing is left below the lower airport', () {
      // OpenSky's take-off from Hamburg (16 m) on a day of high pressure:
      // barometric altitudes in steps of 1000 ft, starting at -1000 ft.
      final filled = TrackTools.fillAltitudes(
        [
          _point(0, altitude: -304),
          _point(1, altitude: 0),
          _point(2, altitude: 304),
          _point(3, altitude: 0),
        ],
        departureElevation: 16,
        arrivalElevation: 111,
      );

      expect(filled.map((p) => p.altitude), [16, 16, 304, 16]);
      // Without airports there is nothing to go by: left as it came.
      expect(
        TrackTools.fillAltitudes([
          _point(0, altitude: -304),
          _point(1, altitude: 304),
        ]).map((p) => p.altitude),
        [-304, 304],
      );
      // One airport is enough.
      expect(
        TrackTools.fillAltitudes([
          _point(0, altitude: -304),
          _point(1, altitude: 304),
        ], arrivalElevation: 111).map((p) => p.altitude),
        [111, 304],
      );
    });

    test('a track that never left the ground stays level', () {
      final filled = TrackTools.fillAltitudes([
        _point(0, onGround: true),
        _point(1, onGround: true),
      ], arrivalElevation: 50);

      expect(filled.map((p) => p.altitude), [50, 50]);
    });
  });

  test('fillSpeeds works the speed out from the positions', () {
    // One minute of arc of latitude is one nautical mile: 1.852 km.
    final filled = TrackTools.fillSpeeds([
      _point(0),
      _point(36, lat: 45 + 1 / 60),
      _point(40, lat: 45 + 2 / 60, speed: 42),
    ]);

    expect(filled[0].speed, closeTo(185.2, 0.5));
    expect(filled[1].speed, closeTo(185.2, 0.5));
    // A speed the provider gave is never replaced.
    expect(filled[2].speed, 42);
  });

  group('thin', () {
    test('leaves short lists alone', () {
      final values = [1, 2, 3];
      expect(TrackTools.thin(values, 10, (v) => v), same(values));
    });

    test('keeps the ends and the peaks', () {
      final values = [for (var i = 0; i < 1000; i++) i == 437 ? 9000 : i % 7];
      final thinned = TrackTools.thin(values, 100, (v) => v);

      expect(thinned.length, lessThanOrEqualTo(100));
      expect(thinned.first, values.first);
      expect(thinned.last, values.last);
      expect(thinned, contains(9000));
    });

    test('keeps the order', () {
      final values = [for (var i = 0; i < 500; i++) (i, (i * 37) % 101)];
      final thinned = TrackTools.thin(values, 60, (v) => v.$2);

      final positions = [for (final v in thinned) v.$1];
      expect(positions, [...positions]..sort());
    });
  });
}
