import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';
import '../services/flight_service.dart';
import '../services/location_service.dart';

final flightServiceProvider = Provider<FlightService>((ref) {
  final db = ref.watch(databaseProvider);
  return FlightService(db);
});

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class FlightListNotifier extends Notifier<List<FlightWithStats>> {
  late final FlightService _service;

  @override
  List<FlightWithStats> build() {
    _service = ref.watch(flightServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    return _service.recordedSessions;
  }

  void _onServiceChange() {
    state = _service.recordedSessions;
  }

  void refresh() {
    _onServiceChange();
  }
}

final flightListProvider = NotifierProvider<FlightListNotifier, List<FlightWithStats>>(FlightListNotifier.new);

class RecordingStateNotifier extends Notifier<bool> {
  late final FlightService _service;

  @override
  bool build() {
    _service = ref.watch(flightServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    return _service.activeSession != null;
  }

  void _onServiceChange() {
    state = _service.activeSession != null;
  }

  void refresh() {
    _onServiceChange();
  }
}

final recordingStateProvider = NotifierProvider<RecordingStateNotifier, bool>(RecordingStateNotifier.new);

class ActiveFlightNotifier extends Notifier<FlightWithStats?> {
  late final FlightService _service;

  @override
  FlightWithStats? build() {
    _service = ref.watch(flightServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    return _service.activeSession;
  }

  void _onServiceChange() {
    state = _service.activeSession;
  }

  void refresh() {
    _onServiceChange();
  }

  void setFlight(FlightWithStats? flight) {
    state = flight;
  }
}

final activeFlightProvider = NotifierProvider<ActiveFlightNotifier, FlightWithStats?>(ActiveFlightNotifier.new);
