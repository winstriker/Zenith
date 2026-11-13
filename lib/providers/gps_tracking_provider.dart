import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/flight_repository.dart';
import '../services/location_service.dart';

/// Controller for GPS tracking during flight recording
/// Manages location stream subscription and provides debounced UI updates
class GpsTrackingController extends AsyncNotifier<void> {
  StreamSubscription<Map<String, double>>? _locationSubscription;
  Timer? _debounceTimer;
  Map<String, double>? _latestLocation;

  @override
  FutureOr<void> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _locationSubscription?.cancel();
    });
    return null;
  }

  /// Start GPS tracking for a flight session
  Future<void> startTracking(int flightId, FlightRepository repository) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    try {
      final locationService = LocationService();
      await locationService.startTracking();

      _locationSubscription = locationService.locationStream.listen((location) {
        _latestLocation = location;
        _debounceLocationUpdate(flightId, repository);
      });

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Debounce location updates to avoid excessive UI rebuilds
  void _debounceLocationUpdate(int flightId, FlightRepository repository) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_latestLocation != null) {
        final loc = _latestLocation!;
        repository.addDataPoint(
          flightId: flightId,
          latitude: loc['latitude']!,
          longitude: loc['longitude']!,
          altitude: loc['altitude']!,
          timestamp: DateTime.now(),
          speed: loc['speed'],
          heading: loc['heading'],
        );
        _latestLocation = null;
      }
    });
  }

  /// Stop GPS tracking
  Future<void> stopTracking() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    LocationService().stopTracking();
    state = const AsyncData(null);
  }

  /// Get the latest location for UI display (non-debounced)
  Map<String, double>? get latestLocation => _latestLocation;

  Future<void> cleanup() => stopTracking();

  bool isTracking() {
    return _locationSubscription != null;
  }
}

final gpsTrackingControllerProvider =
    AsyncNotifierProvider<GpsTrackingController, void>(
      GpsTrackingController.new,
    );
