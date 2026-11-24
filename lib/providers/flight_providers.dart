import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/flight_repository.dart';
import '../services/database.dart';
import '../services/flight_service.dart';
import '../services/person_photo_store.dart';
import 'database_provider.dart';

/// Which part of the logbook a paged flight list shows.
typedef FlightsPageKey = ({int limit, String query, DateTime? day});

/// The newest `limit` recorded flights matching `query` and, when given,
/// departed on `day`. Lists load older flights by asking a bigger `limit`.
final recordedFlightsPageProvider = StreamProvider.autoDispose
    .family<List<FlightWithStats>, FlightsPageKey>((ref, key) {
      return ref
          .watch(flightRepositoryProvider)
          .watchRecordedFlightsPage(
            limit: key.limit,
            query: key.query,
            day: key.day,
          );
    });

/// How many recorded flights there are.
final recordedFlightCountProvider = StreamProvider<int>((ref) {
  return ref.watch(flightRepositoryProvider).watchRecordedFlightCount();
});

/// Recorded flights still to be completed, newest first.
final temporaryFlightsProvider = StreamProvider<List<FlightWithStats>>((ref) {
  return ref.watch(flightRepositoryProvider).watchTemporaryFlights();
});

/// A flight; null once deleted.
final flightByIdStreamProvider = StreamProvider.autoDispose
    .family<FlightWithStats?, int>(
      (ref, id) => ref.watch(flightRepositoryProvider).watchFlightById(id),
    );

/// Minutes flown in the whole logbook.
final totalFlightTimeProvider = StreamProvider<int>(
  (ref) => ref.watch(flightRepositoryProvider).watchTotalFlightTime(),
);

/// Saves and deletes flights.
final flightServiceProvider = Provider<FlightService>((ref) {
  final db = ref.watch(databaseProvider);
  return FlightService(db, ref.watch(signatureStoreProvider));
});
