class FlightPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;
  final double? speed;
  final double? heading;

  const FlightPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'timestamp': timestamp.toIso8601String(),
    'speed': speed,
    'heading': heading,
  };

  factory FlightPoint.fromJson(Map<String, dynamic> json) => FlightPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitude: (json['altitude'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    speed: (json['speed'] as num?)?.toDouble(),
    heading: (json['heading'] as num?)?.toDouble(),
  );
}
