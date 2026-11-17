import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/flight_repository.dart';
import '../services/database.dart';
import '../services/flight_service.dart';
import '../services/location_service.dart';
import '../services/person_photo_store.dart';
import 'database_provider.dart';

// Flight Repository Provider
// Provided by flight_repository.dart

/// Stream of all recorded flights (new reactive approach)
final flightListStreamProvider = StreamProvider<List<FlightWithStats>>((ref) {
  final repository = ref.watch(flightRepositoryProvider);
  return repository.watchRecordedFlights();
});

/// Stream of active recording session
final activeFlightStreamProvider = StreamProvider<FlightWithStats?>((ref) {
  final repository = ref.watch(flightRepositoryProvider);
  return repository.watchActiveFlight();
});

/// Stream of a specific flight by ID
final flightByIdStreamProvider = StreamProvider.family<FlightWithStats?, int>((
  ref,
  flightId,
) {
  final repository = ref.watch(flightRepositoryProvider);
  return repository.watchFlightById(flightId);
});

/// Stream of flights for a specific aircraft
final flightsForAircraftStreamProvider =
    StreamProvider.family<List<FlightWithStats>, int>((ref, aircraftId) {
      final repository = ref.watch(flightRepositoryProvider);
      return repository.watchFlightsForAircraft(aircraftId);
    });

final totalFlightTimeProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(flightRepositoryProvider);
  return repository.watchTotalFlightTime();
});

/// Location service provider (singleton with proper disposal)
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

// Legacy flight service provider (for mutation operations)
final flightServiceProvider = Provider<FlightService>((ref) {
  final db = ref.watch(databaseProvider);
  return FlightService(db, ref.watch(signatureStoreProvider));
});
