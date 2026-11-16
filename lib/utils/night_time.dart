import 'dart:math';

/// A point on the earth, in degrees.
typedef GeoPoint = ({double latitude, double longitude});

/// Where an aircraft was at a given time, in degrees.
typedef TimedPosition = ({DateTime time, double latitude, double longitude});

/// Night time as EASA defines it (Part-FCL / Reg. 965/2012, "night"): the
/// period between the end of evening civil twilight and the beginning of
/// morning civil twilight, i.e. while the centre of the sun is more than 6°
/// below the horizon.
class NightTime {
  NightTime._();

  /// Elevation of the sun's centre at the end of civil twilight.
  static const civilTwilightElevation = -6.0;

  /// The time between [departure] and [arrival] flown at night, assuming a
  /// great-circle route flown at constant speed from [from] to [to].
  ///
  /// Zero when [arrival] is not after [departure].
  static Duration between({
    required DateTime departure,
    required DateTime arrival,
    required GeoPoint from,
    required GeoPoint to,
  }) => along(
    [
      (time: departure, latitude: from.latitude, longitude: from.longitude),
      (time: arrival, latitude: to.latitude, longitude: to.longitude),
    ],
    departure: departure,
    arrival: arrival,
  );

  /// The time between [departure] and [arrival] flown at night along [path]
  /// (in time order): between two of its positions the aircraft is taken to
  /// fly the great circle at constant speed; before the first and after the
  /// last it is taken to stay put. The sun is checked once a minute, at the
  /// middle of each minute.
  ///
  /// Zero when [arrival] is not after [departure], or [path] is empty.
  static Duration along(
    List<TimedPosition> path, {
    required DateTime departure,
    required DateTime arrival,
  }) {
    final total = arrival.difference(departure).inSeconds;
    if (total <= 0 || path.isEmpty) return Duration.zero;
    // Index of the first position after the time being checked: times only
    // go forward, so does it.
    var next = 0;
    var nightSeconds = 0;
    for (var start = 0; start < total; start += 60) {
      final end = min(start + 60, total);
      final middle = (start + end) / 2;
      final time = departure.add(
        Duration(milliseconds: (middle * 1000).round()),
      );
      while (next < path.length && !path[next].time.isAfter(time)) {
        next++;
      }
      final GeoPoint position;
      if (next == 0) {
        position = _point(path.first);
      } else if (next == path.length) {
        position = _point(path.last);
      } else {
        final a = path[next - 1];
        final b = path[next];
        final span = b.time.difference(a.time).inMilliseconds;
        final fraction = span <= 0
            ? 1.0
            : time.difference(a.time).inMilliseconds / span;
        position = _GreatCircle(_point(a), _point(b)).at(fraction);
      }
      if (isNight(time, position)) nightSeconds += end - start;
    }
    return Duration(minutes: (nightSeconds / 60).round());
  }

  static GeoPoint _point(TimedPosition p) =>
      (latitude: p.latitude, longitude: p.longitude);

  /// Whether it is night at [position] at [time].
  static bool isNight(DateTime time, GeoPoint position) =>
      sunElevation(time, position) < civilTwilightElevation;

  /// Elevation of the sun's centre above the horizon, in degrees, without
  /// refraction (twilight is defined on the geometric position). Accurate to
  /// about 0.01° between 1950 and 2050 (Astronomical Almanac's low precision
  /// formulas): well under a minute of twilight.
  static double sunElevation(DateTime time, GeoPoint position) {
    // Days since J2000.0.
    final n =
        time.toUtc().millisecondsSinceEpoch / 86400000.0 +
        2440587.5 -
        2451545.0;
    final meanLongitude = _normalize(280.460 + 0.9856474 * n);
    final meanAnomaly = _rad(_normalize(357.528 + 0.9856003 * n));
    final eclipticLongitude = _rad(
      meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly),
    );
    final obliquity = _rad(23.439 - 0.0000004 * n);

    final rightAscension = atan2(
      cos(obliquity) * sin(eclipticLongitude),
      cos(eclipticLongitude),
    );
    final declination = asin(sin(obliquity) * sin(eclipticLongitude));

    // Greenwich mean sidereal time, in degrees.
    final gmst = _normalize(280.46061837 + 360.98564736629 * n);
    final hourAngle = _rad(gmst + position.longitude) - rightAscension;
    final latitude = _rad(position.latitude);

    return _deg(
      asin(
        sin(latitude) * sin(declination) +
            cos(latitude) * cos(declination) * cos(hourAngle),
      ),
    );
  }

  static double _normalize(double degrees) {
    final d = degrees % 360;
    return d < 0 ? d + 360 : d;
  }

  static double _rad(double degrees) => degrees * pi / 180;
  static double _deg(double radians) => radians * 180 / pi;
}

/// Positions along the great circle from one point to another.
class _GreatCircle {
  _GreatCircle(GeoPoint from, GeoPoint to)
    : _a = _vector(from),
      _b = _vector(to) {
    final dot = (_a[0] * _b[0] + _a[1] * _b[1] + _a[2] * _b[2]).clamp(
      -1.0,
      1.0,
    );
    _angle = acos(dot);
  }

  final List<double> _a;
  final List<double> _b;
  late final double _angle;

  static List<double> _vector(GeoPoint p) {
    final lat = p.latitude * pi / 180;
    final lon = p.longitude * pi / 180;
    return [cos(lat) * cos(lon), cos(lat) * sin(lon), sin(lat)];
  }

  /// The point [fraction] (0..1) of the way.
  GeoPoint at(double fraction) {
    final List<double> v;
    // Same place (or opposite ends of the earth, where any route will do):
    // no interpolation.
    if (_angle < 1e-9 || (pi - _angle) < 1e-9) {
      v = fraction < 0.5 ? _a : _b;
    } else {
      final s = sin(_angle);
      final wa = sin((1 - fraction) * _angle) / s;
      final wb = sin(fraction * _angle) / s;
      v = [
        wa * _a[0] + wb * _b[0],
        wa * _a[1] + wb * _b[1],
        wa * _a[2] + wb * _b[2],
      ];
    }
    return (
      latitude: atan2(v[2], sqrt(v[0] * v[0] + v[1] * v[1])) * 180 / pi,
      longitude: atan2(v[1], v[0]) * 180 / pi,
    );
  }
}
