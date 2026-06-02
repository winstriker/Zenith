import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight_session.dart';
import '../services/flight_service.dart';
import '../services/location_service.dart';

final flightServiceProvider = Provider<FlightService>((ref) => FlightService());

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class FlightListNotifier extends Notifier<List<FlightSession>> {
  @override
  List<FlightSession> build() => FlightService().recordedSessions;

  void refresh() {
    state = FlightService().recordedSessions;
  }
}

final flightListProvider = NotifierProvider<FlightListNotifier, List<FlightSession>>(FlightListNotifier.new);

class RecordingStateNotifier extends Notifier<bool> {
  @override
  bool build() => FlightService().activeSession != null;
}

final recordingStateProvider = NotifierProvider<RecordingStateNotifier, bool>(RecordingStateNotifier.new);

class ActiveFlightNotifier extends Notifier<FlightSession?> {
  @override
  FlightSession? build() => FlightService().activeSession;

  void refresh() {
    state = FlightService().activeSession;
  }

  void setFlight(FlightSession? flight) {
    state = flight;
  }
}

final activeFlightProvider = NotifierProvider<ActiveFlightNotifier, FlightSession?>(ActiveFlightNotifier.new);
