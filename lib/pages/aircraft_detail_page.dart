import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_details_card.dart';
import '../widgets/flight_card.dart';
import '../widgets/info_chip.dart';
import 'aircraft_form_page.dart';
import 'flight_detail_page.dart';

class AircraftDetailPage extends ConsumerWidget {
  const AircraftDetailPage({super.key, required this.aircraftId});
  final int aircraftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aircraft = ref.watch(aircraftWithStatsByIdStreamProvider(aircraftId));
    final flights = ref.watch(flightsForAircraftStreamProvider(aircraftId));
    return aircraft.when(
      data: (aircraft) {
        if (aircraft == null) {
          return const Text("Error while loading aircraft!");
        }
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final hours = aircraft.totalFlightTime != null
            ? '${(aircraft.totalFlightTime!.inMinutes / 60).toStringAsFixed(1)}h'
            : null;

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          floatingActionButton: FloatingActionButton(
            heroTag: "closeFab",
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
          body: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              heroTag: "editFab",
              label: const Text("Edit"),
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AircraftFormPage(aircraft: aircraft),
                ),
              ),
            ),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 280,
                        //TODO: Airplane image
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.secondaryContainer,
                                cs.secondaryContainer.withValues(alpha: 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 200),
                            AircraftDetailsCard(
                              aircraft: aircraft,
                              useOuterPadding: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Flights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                flights.when(
                  data: (flights) {
                    if (flights.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.flight_land,
                                  size: 48,
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No flights with this aircraft yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index >= flights.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return FlightCard(
                            flight: flights[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => FlightDetailPage(
                                    flightId: flights[index].flight.id,
                                  ),
                                ),
                              );
                            },
                          );
                        }, childCount: flights.length),
                      );
                    }
                  },
                  error: (e, _) {
                    return const Text(
                      "Error while loading flights for this aircraft!",
                    );
                  },
                  loading: () {
                    return const CircularProgressIndicator();
                  },
                ),
              ],
            ),
          ),
        );
      },
      error: (_, _) {
        return const Text("Error while loading aircraft!");
      },
      loading: () {
        return const CircularProgressIndicator();
      },
    );
  }
}
