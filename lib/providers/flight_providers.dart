import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight_session.dart';
import '../services/flight_service.dart';
import '../services/location_service.dart';

final flightServiceProvider = Provider<FlightService>((ref) => FlightService());

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class FlightListNotifier extends StateNotifier<List<FlightSession>> {
  FlightListNotifier() : super(FlightService().recordedSessions);

  void refresh() {
    state = FlightService().recordedSessions;
  }
}

final flightListProvider = StateNotifierProvider<FlightListNotifier, List<FlightSession>>((ref) {
  return FlightListNotifier();
});

final recordingStateProvider = StateProvider<bool>((ref) => false);

class ActiveFlightNotifier extends StateNotifier<FlightSession?> {
  ActiveFlightNotifier() : super(FlightService().activeSession);

  void refresh() {
    state = FlightService().activeSession;
  }

  void setFlight(FlightSession flight) {
    state = flight;
  }
}

final activeFlightProvider = StateNotifierProvider<ActiveFlightNotifier, FlightSession?>((ref) {
  return ActiveFlightNotifier();
});
