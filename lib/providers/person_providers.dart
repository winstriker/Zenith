import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/flight_repository.dart';
import '../repositories/person_repository.dart';
import '../services/database.dart';
import 'database_provider.dart';

/// People matching a search query, most recently flown with first.
final peopleProvider = StreamProvider.autoDispose
    .family<List<PersonWithLastFlight>, String>((ref, query) {
      return ref.watch(personRepositoryProvider).watchPeople(query: query);
    });

/// One person with flight stats; null once deleted.
final personProvider = StreamProvider.autoDispose
    .family<PersonWithLastFlight?, int>((ref, id) {
      return ref.watch(personRepositoryProvider).watchPerson(id);
    });

/// Flights the person was on, newest first.
final personFlightsProvider = StreamProvider.autoDispose
    .family<List<FlightWithStats>, int>((ref, id) {
      return ref.watch(flightRepositoryProvider).watchFlightsForPerson(id);
    });

/// The person's role per flight id.
final personRolesProvider = StreamProvider.autoDispose
    .family<Map<int, CrewRole>, int>((ref, id) {
      return ref.watch(personRepositoryProvider).watchRoles(id);
    });

/// Crew of a flight (excluding self), live.
final flightCrewProvider = StreamProvider.autoDispose
    .family<List<CrewMember>, int>((ref, flightId) {
      return ref.watch(databaseProvider).watchFlightCrew(flightId);
    });
