import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';

// Aircraft Repository Provider
// Provided by aircraft_repository.dart

/// Stream of all aircraft with stats
final aircraftListStreamProvider = StreamProvider<List<AircraftWithStats>>((ref) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAircraftsWithStats();
});

/// Stream of a specific aircraft
final aircraftByIdStreamProvider = StreamProvider.family<Aircraft?, int>((ref, aircraftId) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAircraft(aircraftId);
});

/// Stream of flights for a specific aircraft
final flightsForAircraftStreamProvider = StreamProvider.family<List<FlightWithStats>, int>((ref, aircraftId) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchFlightsForAircraft(aircraftId);
});