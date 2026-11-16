import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/night_time.dart';

const _malpensa = (latitude: 45.63, longitude: 8.72);

void main() {
  group('sunElevation', () {
    test('is close to 90° - latitude + declination at solar noon', () {
      // June solstice: declination +23.44°, solar noon at LIMC ~11:24 UTC.
      final noon = DateTime.utc(2026, 6, 21, 11, 24);
      expect(
        NightTime.sunElevation(noon, _malpensa),
        closeTo(90 - 45.63 + 23.44, 0.3),
      );
    });

    test('is far below the horizon at midnight in winter', () {
      final midnight = DateTime.utc(2026, 12, 21, 23, 24);
      expect(
        NightTime.sunElevation(midnight, _malpensa),
        // Lower culmination: latitude + declination - 90°.
        closeTo(45.63 - 23.44 - 90, 0.3),
      );
    });
  });

  test('evening civil twilight ends when the sun is 6° below', () {
    // By hand for LIMC on the December solstice: hour angle of -6° is
    // 73.7°, 4h55m after solar noon at ~11:23 UTC, so ~16:18 UTC.
    var t = DateTime.utc(2026, 12, 21, 15);
    while (!NightTime.isNight(t, _malpensa)) {
      t = t.add(const Duration(minutes: 1));
    }
    expect(
      t.difference(DateTime.utc(2026, 12, 21, 16, 18)).inMinutes.abs(),
      lessThanOrEqualTo(3),
    );
  });

  group('between', () {
    Duration local(DateTime dep, DateTime arr) => NightTime.between(
      departure: dep,
      arrival: arr,
      from: _malpensa,
      to: _malpensa,
    );

    test('a day flight has no night time', () {
      expect(
        local(DateTime.utc(2026, 6, 21, 9), DateTime.utc(2026, 6, 21, 11)),
        Duration.zero,
      );
    });

    test('a flight wholly after dusk is all night', () {
      expect(
        local(
          DateTime.utc(2026, 12, 21, 19),
          DateTime.utc(2026, 12, 21, 20, 30),
        ),
        const Duration(minutes: 90),
      );
    });

    test('sunset itself is not night: only after civil twilight', () {
      // Sunset at LIMC on 21 Dec is ~15:43 UTC, dusk ~16:18 UTC.
      final night = local(
        DateTime.utc(2026, 12, 21, 15, 48),
        DateTime.utc(2026, 12, 21, 16, 48),
      );
      expect(night.inMinutes, inInclusiveRange(27, 33));
    });

    test('no time, no night', () {
      final t = DateTime.utc(2026, 12, 21, 22);
      expect(local(t, t), Duration.zero);
      expect(local(t, t.subtract(const Duration(hours: 1))), Duration.zero);
    });

    test('follows the route: flying east into the sunrise', () {
      // Equator, 6 hours from 0° to 90°E: local time goes from 03:00 to
      // 15:00, so night at the start and day at the end. Dawn (civil) is at
      // ~05:38 local: 0.22 of the way, at ~01:20 into the flight.
      final dep = DateTime.utc(2026, 3, 20, 3);
      final night = NightTime.between(
        departure: dep,
        arrival: dep.add(const Duration(hours: 6)),
        from: (latitude: 0, longitude: 0),
        to: (latitude: 0, longitude: 90),
      );
      expect(night.inMinutes, inInclusiveRange(75, 85));
      expect(night, greaterThan(Duration.zero));
      expect(night, lessThan(const Duration(hours: 6)));
    });
  });

  group('along a track', () {
    final dep = DateTime.utc(2026, 3, 20, 16);
    final arr = DateTime.utc(2026, 3, 20, 20);
    TimedPosition at(DateTime time, double lon) =>
        (time: time, latitude: 0, longitude: lon);

    test('follows where the aircraft was, not the straight line', () {
      // Out and back from 0°: dusk there is at ~18:31 UTC, but by 17:00 UTC
      // the aircraft is far east, where night has already fallen.
      final direct = NightTime.along(
        [at(dep, 0), at(arr, 0)],
        departure: dep,
        arrival: arr,
      );
      final viaEast = NightTime.along(
        [
          at(dep, 0),
          at(DateTime.utc(2026, 3, 20, 17), 90),
          at(DateTime.utc(2026, 3, 20, 19), 90),
          at(arr, 0),
        ],
        departure: dep,
        arrival: arr,
      );
      expect(direct.inMinutes, inInclusiveRange(85, 93));
      expect(viaEast, greaterThan(direct + const Duration(minutes: 60)));
    });

    test('stays at the ends outside the track', () {
      // One position only: as if the aircraft never moved.
      final night = NightTime.along(
        [at(DateTime.utc(2026, 3, 20, 18), 0)],
        departure: dep,
        arrival: arr,
      );
      expect(
        night,
        NightTime.between(
          departure: dep,
          arrival: arr,
          from: (latitude: 0, longitude: 0),
          to: (latitude: 0, longitude: 0),
        ),
      );
    });
  });
}
