import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  Timer? _gpsTimer;
  Timer? _mockTimer;
  bool get isTracking => _gpsTimer != null || _mockTimer != null;

  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  double _speed = 0;
  double _heading = 0;

  final _locationStream = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get locationStream => _locationStream.stream;

  void startTracking() {
    if (isTracking) return;

    if (kDebugMode) {
      _startMockTracking();
    } else {
      _startRealTracking();
    }
  }

  void _startRealTracking() {
    _pollGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollGps());
  }

  Future<void> _pollGps() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
      _speed = position.speed;
      _heading = position.heading;

      _locationStream.add({
        'latitude': _latitude,
        'longitude': _longitude,
        'altitude': _altitude,
        'speed': _speed * 3.6,
        'heading': _heading,
      });
    } catch (_) {}
  }

  void _startMockTracking() {
    _latitude = 51.4700;
    _longitude = -0.4543;
    _altitude = 0;
    _speed = 0;
    _heading = 0;

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateMovement();
      _locationStream.add({
        'latitude': _latitude,
        'longitude': _longitude,
        'altitude': _altitude,
        'speed': _speed,
        'heading': _heading,
      });
    });
  }

  void stopTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  void _simulateMovement() {
    final rng = Random();
    if (_altitude < 1000) {
      _altitude += rng.nextDouble() * 50 + 20;
      _speed = 100 + rng.nextDouble() * 50;
    } else if (_altitude < 3000) {
      _altitude += rng.nextDouble() * 30 + 10;
      _speed = 200 + rng.nextDouble() * 50;
    } else {
      _altitude += rng.nextDouble() * 10 - 5;
      _speed = 250 + rng.nextDouble() * 30;
    }
    _altitude = _altitude.clamp(0, 5000);

    _heading += (rng.nextDouble() - 0.5) * 10;
    _heading = _heading % 360;

    final headingRad = _heading * pi / 180;
    final distKm = _speed * 2 / 3600;
    final latChange = distKm / 111.32 * cos(headingRad);
    final lonChange =
        distKm / (111.32 * cos(_latitude * pi / 180)) * sin(headingRad);

    _latitude += latChange;
    _longitude += lonChange;
  }

  void dispose() {
    stopTracking();
    _locationStream.close();
  }
}
