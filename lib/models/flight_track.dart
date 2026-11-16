import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// One position of a flight's track, in the units tracks are stored in.
@immutable
class TrackPoint {
  const TrackPoint({
    required this.time,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.onGround = false,
  });

  /// UTC.
  final DateTime time;
  final double latitude;
  final double longitude;

  /// Metres. Null when not known, as on the ground, where transponders
  /// report no altitude.
  final double? altitude;

  /// Ground speed, km/h.
  final double? speed;

  /// Degrees.
  final double? heading;
  final bool onGround;

  TrackPoint copyWith({double? altitude, double? speed}) => TrackPoint(
    time: time,
    latitude: latitude,
    longitude: longitude,
    altitude: altitude ?? this.altitude,
    speed: speed ?? this.speed,
    heading: heading,
    onGround: onGround,
  );
}

/// Pure helpers that turn what a provider sends into a track worth storing.
abstract final class TrackTools {
  static const feetToMetres = 0.3048;
  static const knotsToKmh = 1.852;

  /// Sorts [points] by time and keeps one per second (tracks are stored to
  /// the second) and only real positions.
  static List<TrackPoint> clean(Iterable<TrackPoint> points) {
    final sorted = [
      for (final p in points)
        if (p.latitude.abs() <= 90 &&
            p.longitude.abs() <= 180 &&
            // Positions of exactly 0/0 are transponders without a fix.
            !(p.latitude == 0 && p.longitude == 0))
          p,
    ]..sort((a, b) => a.time.compareTo(b.time));
    final result = <TrackPoint>[];
    int? lastSecond;
    for (final point in sorted) {
      final second = point.time.millisecondsSinceEpoch ~/ 1000;
      if (second == lastSecond) continue;
      lastSecond = second;
      result.add(point);
    }
    return result;
  }

  /// Cuts [points] (in time order) wherever nothing was received for longer
  /// than [gap].
  static List<List<TrackPoint>> splitAtGaps(
    List<TrackPoint> points,
    Duration gap,
  ) {
    final parts = <List<TrackPoint>>[];
    for (final point in points) {
      if (parts.isEmpty || point.time.difference(parts.last.last.time) > gap) {
        parts.add([]);
      }
      parts.last.add(point);
    }
    return parts;
  }

  /// Gives every point an altitude. Points without one (on the ground,
  /// mostly) take the elevation of the airport they are at when it is
  /// known ([departureElevation] before the first known altitude,
  /// [arrivalElevation] after the last), and otherwise the nearest known
  /// altitude in time. Metres.
  ///
  /// No point is left below the lower of the two airports. What
  /// transponders send is the altitude at standard pressure, often rounded
  /// to hundreds of feet: on a day of high pressure it reads below the
  /// runway, and a take-off would start underground.
  static List<TrackPoint> fillAltitudes(
    List<TrackPoint> points, {
    double? departureElevation,
    double? arrivalElevation,
  }) {
    final floor = switch ((departureElevation, arrivalElevation)) {
      (final departure?, final arrival?) => math.min(departure, arrival),
      (final elevation?, null) || (null, final elevation?) => elevation,
      _ => null,
    };
    TrackPoint at(TrackPoint point, double altitude) => point.copyWith(
      altitude: floor != null && altitude < floor ? floor : altitude,
    );

    final first = points.indexWhere((p) => p.altitude != null);
    if (first < 0) {
      return [for (final p in points) at(p, floor ?? 0)];
    }
    final last = points.lastIndexWhere((p) => p.altitude != null);
    final result = <TrackPoint>[];
    var previous = points[first].altitude!;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (point.altitude != null) {
        previous = point.altitude!;
        result.add(at(point, previous));
      } else if (i < first) {
        result.add(at(point, departureElevation ?? points[first].altitude!));
      } else if (i > last) {
        result.add(at(point, arrivalElevation ?? points[last].altitude!));
      } else {
        result.add(at(point, previous));
      }
    }
    return result;
  }

  /// Works out the ground speed of the points that have none from the
  /// distance and time to the point before (after, for the first).
  static List<TrackPoint> fillSpeeds(List<TrackPoint> points) {
    if (points.length < 2 || points.every((p) => p.speed != null)) {
      return points;
    }
    double? between(TrackPoint a, TrackPoint b) {
      final seconds = b.time.difference(a.time).inMilliseconds / 1000;
      if (seconds <= 0) return null;
      return distanceKm(a, b) / seconds * 3600;
    }

    return [
      for (var i = 0; i < points.length; i++)
        if (points[i].speed != null)
          points[i]
        else
          points[i].copyWith(
            speed: i == 0
                ? between(points[0], points[1])
                : between(points[i - 1], points[i]),
          ),
    ];
  }

  /// Great-circle distance, in kilometres.
  static double distanceKm(TrackPoint a, TrackPoint b) {
    const radius = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radius * 2 * math.asin(math.min(1, math.sqrt(h)));
  }

  /// At most about [maxPoints] of [values], evenly spread, keeping the
  /// lowest and highest of every stretch so that peaks survive. For charts,
  /// which gain nothing from more points than they have pixels.
  static List<T> thin<T>(
    List<T> values,
    int maxPoints,
    num Function(T value) measure,
  ) {
    if (values.length <= maxPoints || maxPoints < 4) return values;
    // Each stretch gives two points, plus the first and last ones.
    final buckets = (maxPoints - 2) ~/ 2;
    final inner = values.length - 2;
    final result = <T>[values.first];
    for (var b = 0; b < buckets; b++) {
      final from = 1 + inner * b ~/ buckets;
      final to = 1 + inner * (b + 1) ~/ buckets;
      if (to <= from) continue;
      var low = from;
      var high = from;
      for (var i = from + 1; i < to; i++) {
        if (measure(values[i]) < measure(values[low])) low = i;
        if (measure(values[i]) > measure(values[high])) high = i;
      }
      result.add(values[math.min(low, high)]);
      if (low != high) result.add(values[math.max(low, high)]);
    }
    result.add(values.last);
    return result;
  }
}
