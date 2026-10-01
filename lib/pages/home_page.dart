import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/user_provider.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/pulsing_dot.dart';
import 'aircraft_detail_page.dart';
import 'aircraft_form_page.dart';
import 'aircrafts_page.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';
import 'flights_page.dart';
import 'recording_page.dart';

final _recentAirportsProvider = FutureProvider<List<Airport>>((ref) {
  final db = ref.read(databaseProvider);
  return db.getRecentAirports();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(flightListStreamProvider);
    final isRecording = ref.watch(gpsTrackingControllerProvider.notifier);
    final aircraftList = ref.watch(aircraftListStreamProvider);
    final nickname = ref.watch(userNicknameProvider);
    final totalFlightTime = ref.watch(totalFlightTimeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(theme, nickname),
          SliverToBoxAdapter(
            child: _buildRecordingBanner(
              context,
              theme,
              isRecording.isTracking(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildQuickStats(
              context,
              theme,
              flights.when(
                data: (val) => val.length,
                error: (_, _) => -1,
                loading: () => 0,
              ),
              totalFlightTime.when(
                data: (val) => val,
                error: (_, _) => -1,
                loading: () => 0,
              ),
              aircraftList.when(
                data: (val) => val.length,
                error: (_, _) => -1,
                loading: () => 0,
              ),
            ),
          ),
          _buildSectionHeader(
            context,
            theme,
            'Recent Flights',
            Icons.flight,
            () => _openFlights(context),
          ),

          flights.when(
            data: (val) {
              final recentFlights = val.take(3).toList();
              if (recentFlights.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyFlights(theme));
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FlightCard(
                      flight: recentFlights[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlightDetailPage(
                            flightId: recentFlights[index].flight.id,
                          ),
                        ),
                      ),
                    ),
                    childCount: recentFlights.length,
                  ),
                );
              }
            },
            error: (_, _) => const SliverToBoxAdapter(
              child: Text("Error while loading flights."),
            ),
            loading: () =>
                const SliverToBoxAdapter(child: CircularProgressIndicator()),
          ),
          _buildAircraftSection(context, theme, aircraftList),
          _buildAirportsSection(context, theme, ref),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String? nickname) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Icon(
                  Icons.flight,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.flight,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nickname ?? 'Pilot',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBanner(
    BuildContext context,
    ThemeData theme,
    bool isRecording,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: isRecording
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const PulsingDot(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recording in progress',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tap to view recording',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordingPage()),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordingPage()),
                    ),
                    icon: const Icon(Icons.fiber_manual_record, size: 22),
                    label: const Text('Start Recording'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlightFormPage()),
                    ),
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Add Flight'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _openFlights(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlightsPage()),
    );
  }

  void _openAircrafts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AircraftsPage()),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    ThemeData theme,
    int flightCount,
    int totalMinutes,
    int aircraftCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _statCard(
            theme,
            Icons.flight_takeoff,
            '$flightCount',
            'Total Flights',
            Colors.blue,
            onTap: () => _openFlights(context),
          ),
          const SizedBox(width: 12),
          _statCard(
            theme,
            Icons.schedule,
            '${(totalMinutes / 60).toInt()}:${totalMinutes % 60 > 9 ? totalMinutes % 60 : "0${totalMinutes % 60}"}h',
            'Flight Time',
            Colors.green,
          ),
          const SizedBox(width: 12),
          _statCard(
            theme,
            Icons.airplanemode_active,
            '$aircraftCount',
            'Aircraft',
            Colors.orange,
            onTap: () => _openAircrafts(context),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback? onSeeAll,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFlights(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: EmptyState(
        icon: Icons.flight,
        title: 'No flights yet',
        subtitle: 'Start recording your first flight!',
        iconSize: 48,
      ),
    );
  }

  Widget _buildAircraftSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<AircraftWithStats>> aircraftList,
  ) {
    return aircraftList.when(
      data: (aircraftList) {
        if (aircraftList.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No aircraft added yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your aircraft to track flight hours.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AircraftsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Your First Aircraft'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final displayAircraft = aircraftList.take(5).toList();
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Aircraft',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AircraftsPage(),
                        ),
                      ),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    itemCount: displayAircraft.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == displayAircraft.length) {
                        return SizedBox(
                          width: 160,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AircraftFormPage(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 32,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Aircraft',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final aws = displayAircraft[index];
                      final ac = aws;
                      final hours = aws.totalFlightTime != null
                          ? '${(aws.totalFlightTime!.inMinutes / 60).toStringAsFixed(1)}h'
                          : null;
                      return SizedBox(
                        width: 160,
                        child: BaseCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AircraftDetailPage(aircraftId: aws.id),
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.airplanemode_active,
                                    size: 18,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const Spacer(),
                                  if (ac.tailNumber != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ac.tailNumber!,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                ac.type,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (ac.model != null)
                                Text(
                                  ac.model!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.flight,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${aws.flightCount} flights',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (hours != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hours,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (_, _) => const SliverToBoxAdapter(
        child: Text("Error while loading aircrafts"),
      ),
      loading: () =>
          const SliverToBoxAdapter(child: CircularProgressIndicator()),
    );
  }

  Widget _buildAirportsSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final airportsAsync = ref.watch(_recentAirportsProvider);

    return airportsAsync.when(
      data: (airports) {
        if (airports.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final displayAirports = airports.take(5).toList();
        return SliverToBoxAdapter(
          child: _buildAirportsList(displayAirports, theme),
        );
      },
      error: (e, s) {
        return const SliverToBoxAdapter(
          child: Text("Error while loading Airports"),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildAirportsList(List<Airport> displayAirports, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_airport,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Airports',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4, right: 4),
              itemCount: displayAirports.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final airport = displayAirports[index];
                return SizedBox(
                  width: 180,
                  child: BaseCard(
                    onTap: () {},
                    padding: const EdgeInsets.all(14),
                    borderRadius: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_airport,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const Spacer(),
                            if (airport.ident != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  airport.ident!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          airport.name ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (airport.municipality != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            airport.municipality!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
