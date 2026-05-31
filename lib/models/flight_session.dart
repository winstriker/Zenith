import 'dart:math';
import 'flight_point.dart';

enum FlightStatus { recorded, inProgress }

class FlightSession {
  final String sessionId;
  final String title;
  final String? aircraftType;
  final String? departure;
  final String? arrival;
  final DateTime startTime;
  final DateTime? endTime;
  final FlightStatus status;
  final List<FlightPoint> points;

  const FlightSession({
    required this.sessionId,
    required this.title,
    this.aircraftType,
    this.departure,
    this.arrival,
    required this.startTime,
    this.endTime,
    this.status = FlightStatus.recorded,
    this.points = const [],
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  double? get maxAltitude {
    if (points.isEmpty) return null;
    return points.map((p) => p.altitude).reduce((a, b) => a > b ? a : b);
  }

  double? get totalDistance {
    if (points.length < 2) return null;
    double dist = 0;
    for (int i = 1; i < points.length; i++) {
      dist += _haversine(
        points[i - 1].latitude, points[i - 1].longitude,
        points[i].latitude, points[i].longitude,
      );
    }
    return dist;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  static double _toRadians(double deg) => deg * 3.141592653589793 / 180;

  FlightSession copyWith({
    String? sessionId,
    String? title,
    String? aircraftType,
    String? departure,
    String? arrival,
    DateTime? startTime,
    DateTime? endTime,
    FlightStatus? status,
    List<FlightPoint>? points,
  }) => FlightSession(
    sessionId: sessionId ?? this.sessionId,
    title: title ?? this.title,
    aircraftType: aircraftType ?? this.aircraftType,
    departure: departure ?? this.departure,
    arrival: arrival ?? this.arrival,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    points: points ?? this.points,
  );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'title': title,
    'aircraftType': aircraftType,
    'departure': departure,
    'arrival': arrival,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'status': status.name,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory FlightSession.fromJson(Map<String, dynamic> json) => FlightSession(
    sessionId: json['sessionId'] as String,
    title: json['title'] as String,
    aircraftType: json['aircraftType'] as String?,
    departure: json['departure'] as String?,
    arrival: json['arrival'] as String?,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    status: FlightStatus.values.firstWhere((e) => e.name == json['status']),
    points: (json['points'] as List<dynamic>?)?.map((p) => FlightPoint.fromJson(p as Map<String, dynamic>)).toList() ?? [],
  );
}
