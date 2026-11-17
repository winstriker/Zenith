import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import '../widgets/aircraft_details_card.dart';
import '../widgets/aircraft_photo_view.dart';
import '../widgets/flight_card.dart';
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
        final photo = aircraft.photo;

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          floatingActionButton: FloatingActionButton(
            heroTag: closeFabHeroTag,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
          body: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              heroTag: primaryFabHeroTag,
              label: const Text("Edit"),
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final deleted = await Navigator.push<bool>(
                  context,
                  AppPageRoute(
                    builder: (_) => AircraftFormPage(aircraft: aircraft),
                  ),
                );
                // Nothing left to show once the aircraft is gone.
                if (deleted == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const cardOverlap = 48.0;
                      final photoHeight =
                          constraints.maxWidth / aircraftPhotoAspectRatio;
                      final cardTop = photoHeight - cardOverlap;
                      return Stack(
                        children: [
                          SizedBox(
                            height: photoHeight,
                            width: double.infinity,
                            child: AircraftPhotoView(
                              photo: photo,
                              placeholder: const AircraftHeaderGradient(),
                            ),
                          ),
                          // Above the part of the photo the details card
                          // covers.
                          if (photo != null && photo.isOnline)
                            Positioned(
                              top: cardTop - 26,
                              left: 16,
                              right: 16,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: AircraftPhotoCredit(photo: photo),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, cardTop, 16, 16),
                            child: AircraftDetailsCard(
                              aircraft: aircraft,
                              useOuterPadding: false,
                            ),
                          ),
                        ],
                      );
                    },
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
                                AppPageRoute<void>(
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
                    return const SliverToBoxAdapter(
                      child: Text(
                        "Error while loading flights for this aircraft!",
                      ),
                    );
                  },
                  loading: () {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
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
