import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  static const _methodChannel = MethodChannel('com.example.logbook/location_service');
  static const _eventChannel = EventChannel('com.example.logbook/location_events');

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<dynamic>? _nativeSubscription;

  bool get isTracking => _gpsSubscription != null || _nativeSubscription != null;

  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  double _speed = 0;
  double _heading = 0;

  final _locationStream = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get locationStream => _locationStream.stream;

  void startTracking() {
    if (isTracking) return;

    _startRealTracking();
  }

  void _startRealTracking() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _startAndroidTracking();
    } else {
      _startIosTracking();
    }
  }

  void _startAndroidTracking() {
    try {
      _methodChannel.invokeMethod('startService');
    } catch (_) {
      _fallbackToGeolocator();
      return;
    }

    _nativeSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      final data = Map<String, dynamic>.from(event as Map);
      _latitude = (data['latitude'] as num).toDouble();
      _longitude = (data['longitude'] as num).toDouble();
      _altitude = (data['altitude'] as num).toDouble().roundToDouble();
      _speed = (data['speed'] as num).toDouble() * 3.6;
      _heading = (data['heading'] as num).toDouble();

      _locationStream.add({
        'latitude': _latitude,
        'longitude': _longitude,
        'altitude': _altitude,
        'speed': _speed,
        'heading': _heading,
      });
    }, onError: (_) {
      _fallbackToGeolocator();
    });
  }

  void _fallbackToGeolocator() {
    _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Logbook',
              notificationText: 'Recording flight...',
              setOngoing: true,
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
    _nativeSubscription?.cancel();
    _nativeSubscription = null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        _methodChannel.invokeMethod('stopService');
      } catch (_) {}
    }
  }

  Future<List<Map<String, dynamic>>> getBufferedData() async {
    if (defaultTargetPlatform != TargetPlatform.android) return [];
    try {
      final result = await _methodChannel.invokeMethod('getBufferedData');
      if (result == null) return [];
      return List<Map<String, dynamic>>.from(result as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> clearBuffer() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _methodChannel.invokeMethod('clearBuffer');
    } catch (_) {}
  }

  void dispose() {
    stopTracking();
    _locationStream.close();
  }
}
