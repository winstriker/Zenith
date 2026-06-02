import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

class LocationService {
  static final LocationService _instance = LocationService._();
  final Logger logger = Logger("Location Service");
  factory LocationService() => _instance;
  LocationService._();

  static const _methodChannel = MethodChannel(
    'com.example.logbook/location_service',
  );

  StreamSubscription<Position>? _gpsSubscription;

  bool get isTracking => _gpsSubscription != null;

  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  double _speed = 0;
  double _heading = 0;

  final _locationStream = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get locationStream => _locationStream.stream;

  Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _methodChannel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  Future<void> startTracking() async {
    if (isTracking) return;

    await _startRealTracking();
  }

  Future<void> _startRealTracking() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _startAndroidTracking();
    } else {
      _startIosTracking();
    }
  }

  Future<void> _startAndroidTracking() async {
    // On Android 13+ the system may block foreground service notifications
    // if POST_NOTIFICATIONS hasn't been granted at runtime.
    try {
      await _methodChannel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
    }

    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,

            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Logbook',
              notificationText: 'Recording flight...',
              setOngoing: true,
              enableWakeLock: true,
            ),
          ),
        ).listen((position) {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _altitude = position.altitude.roundToDouble();
          _speed = position.speed;
          _heading = position.heading;

          _locationStream.add({
            'latitude': _latitude,
            'longitude': _longitude,
            'altitude': _altitude,
            'speed': _speed * 3.6,
            'heading': _heading,
          });
        });
  }

  void _startIosTracking() {
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((position) {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _altitude = position.altitude.roundToDouble();
          _speed = position.speed;
          _heading = position.heading;

          _locationStream.add({
            'latitude': _latitude,
            'longitude': _longitude,
            'altitude': _altitude,
            'speed': _speed * 3.6,
            'heading': _heading,
          });
        });
  }

  void stopTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationStream.close();
  }
}
