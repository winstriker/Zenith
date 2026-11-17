import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../repositories/flight_repository.dart';
import '../repositories/simulator_repository.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/flight_card.dart';
import '../widgets/info_row.dart';
import '../widgets/page_title.dart';
import '../widgets/simulator_card.dart';
import 'flight_detail_page.dart';
import 'simulator_form_page.dart';

final _sessionsProvider = StreamProvider.autoDispose
    .family<List<FlightWithStats>, int>(
      (ref, id) =>
          ref.watch(flightRepositoryProvider).watchSessionsForSimulator(id),
    );

/// A simulator, what it is and the sessions flown in it.
class SimulatorDetailPage extends ConsumerWidget {
  const SimulatorDetailPage({super.key, required this.simulatorId});
  final int simulatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulator = ref.watch(simulatorByIdProvider(simulatorId));
    final sessions = ref.watch(_sessionsProvider(simulatorId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sim = simulator.value;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: sim == null
            ? null
            : FloatingActionButton.extended(
                heroTag: primaryFabHeroTag,
                label: const Text('Edit'),
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final deleted = await Navigator.push<Object?>(
                    context,
                    AppPageRoute(
                      builder: (_) => SimulatorFormPage(simulator: sim),
                    ),
                  );
                  if (deleted == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
        body: switch (simulator) {
          AsyncValue(:final error?) => Center(child: Text('Error: $error')),
          AsyncValue(hasValue: false) => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when sim == null => const Center(
            child: Text('Simulator not found'),
          ),
          _ => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageTitle(sim.title, belowCloseButton: true),
              ),
              SliverToBoxAdapter(child: SimulatorCard(simulator: sim)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DetailsCard(simulator: sim),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Sessions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ...switch (sessions.value) {
                null => const [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
                [] => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No sessions in this simulator yet',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                final list => [
                  SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => FlightCard(
                      flight: list[index],
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute<void>(
                          builder: (_) =>
                              FlightDetailPage(flightId: list[index].flight.id),
                        ),
                      ),
                    ),
                  ),
                ],
              },
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        },
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.simulator});
  final SimulatorWithStats simulator;

  @override
  Widget build(BuildContext context) {
    final s = simulator.simulator;
    final type = simulator.type;
    final c = s.aircraftClass;
    String? orNull(String? v) => v == null || v.trim().isEmpty ? null : v;

    final rows = <(String, String)>[
      ('Device', s.kind.description),
      if (orNull(s.level) != null) ('Level', s.level!),
      if (orNull(s.qualificationNumber) != null)
        ('Qualification', s.qualificationNumber!),
      if (orNull(s.organisation) != null) ('Organisation', s.organisation!),
      if (type != null)
        (
          'Aircraft type',
          '${type.manufacturer} ${type.modelFullName} (${type.designator})',
        ),
      if (c != null)
        (
          c == AircraftClass.type ? 'Type rating' : 'Class',
          c == AircraftClass.type ? s.typeRating ?? c.label : c.label,
        ),
      (
        'Total time',
        '${DurationFormatter.hm(Duration(minutes: simulator.totalMinutes))} '
            'in ${simulator.sessionCount} '
            '${simulator.sessionCount == 1 ? 'session' : 'sessions'}',
      ),
      ('Logbook', simulator.logbookType),
      if (orNull(s.notes) != null) ('Notes', s.notes!),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final (label, value) in rows)
              InfoRow(label: label, value: value),
          ],
        ),
      ),
    );
  }
}
