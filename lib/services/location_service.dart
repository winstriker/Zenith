import 'dart:async';
import 'dart:math';

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  Timer? _timer;
  bool get isTracking => _timer != null;

  // Simulated starting position (near an airport)
  double _lat = 51.4700;
  double _lon = -0.4543;
  double _alt = 0;
  double _speed = 0;
  double _heading = 0;

  final _locationStream = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get locationStream => _locationStream.stream;

  void startTracking() {
    if (_timer != null) return;
    _lat = 51.4700;
    _lon = -0.4543;
    _alt = 0;
    _speed = 0;
    _heading = 0;

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateMovement();
      _locationStream.add({
        'latitude': _lat,
        'longitude': _lon,
        'altitude': _alt,
        'speed': _speed,
        'heading': _heading,
      });
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  void _simulateMovement() {
    final rng = Random();
    // Simulate takeoff and climbing
    if (_alt < 1000) {
      _alt += rng.nextDouble() * 50 + 20;
      _speed = 100 + rng.nextDouble() * 50;
    } else if (_alt < 3000) {
      _alt += rng.nextDouble() * 30 + 10;
      _speed = 200 + rng.nextDouble() * 50;
    } else {
      _alt += rng.nextDouble() * 10 - 5;
      _speed = 250 + rng.nextDouble() * 30;
    }
    _alt = _alt.clamp(0, 5000);

    _heading += (rng.nextDouble() - 0.5) * 10;
    _heading = _heading % 360;

    final headingRad = _heading * pi / 180;
    final distKm = _speed * 2 / 3600; // distance in 2 seconds
    final latChange = distKm / 111.32 * cos(headingRad);
    final lonChange = distKm / (111.32 * cos(_lat * pi / 180)) * sin(headingRad);

    _lat += latChange;
    _lon += lonChange;
  }

  void dispose() {
    stopTracking();
    _locationStream.close();
  }
}
