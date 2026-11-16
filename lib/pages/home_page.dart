import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/user_provider.dart';
import '../utils/duration_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/speed_dial_fab.dart';
import 'adsb_track_page.dart';
import 'aircrafts_page.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';
import 'flights_page.dart';
import 'recording_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(flightListStreamProvider);
    final gpsController = ref.watch(gpsTrackingControllerProvider.notifier);
    final aircraftList = ref.watch(aircraftListStreamProvider);
    final nickname = ref.watch(userNicknameProvider);
    final totalFlightTime = ref.watch(totalFlightTimeProvider);
    final isRecording = gpsController.isTracking();

    return Scaffold(
      floatingActionButton: const _HomeFabs(),
      body: CustomScrollView(
        slivers: [
          _HomeHeader(nickname: nickname),
          if (isRecording) const SliverToBoxAdapter(child: _RecordingBanner()),
          SliverToBoxAdapter(
            child: _QuickStats(
              flightCount: flights.when(
                data: (val) => val.length,
                error: (_, _) => -1,
                loading: () => 0,
              ),
              totalMinutes: totalFlightTime.when(
                data: (val) => val,
                error: (_, _) => -1,
                loading: () => 0,
              ),
              aircraftCount: aircraftList.when(
                data: (val) => val.length,
                error: (_, _) => -1,
                loading: () => 0,
              ),
            ),
          ),
          _SectionHeader(
            title: 'Recent Flights',
            icon: Icons.flight,
            onSeeAll: () => _openFlights(context),
          ),
          flights.when(
            data: (val) {
              final recentFlights = val.take(3).toList();
              if (recentFlights.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    child: EmptyState(
                      icon: Icons.flight,
                      title: 'No flights yet',
                      subtitle: 'Start recording your first flight!',
                      iconSize: 48,
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FlightCard(
                    flight: recentFlights[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => FlightDetailPage(
                          flightId: recentFlights[index].flight.id,
                        ),
                      ),
                    ),
                  ),
                  childCount: recentFlights.length,
                ),
              );
            },
            error: (_, _) => const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Error while loading flights',
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          // Keeps the last flight clear of the FAB column and the nav bar.
          SliverToBoxAdapter(
            child: SizedBox(height: 136 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}

void _openFlights(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const FlightsPage()),
  );
}

void _openAircrafts(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const AircraftsPage()),
  );
}

void _openRecording(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const RecordingPage()),
  );
}

/// "Add Flight" FAB with a small "more" FAB above it that pops up the less
/// common ways to log a flight (recording, ADS-B import).
class _HomeFabs extends StatelessWidget {
  const _HomeFabs();

  Future<void> _importAdsb(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdsbTrackPage.import()),
    );
    if (imported == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Flight imported')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SpeedDialFab(
      actions: [
        SpeedDialAction(
          heroTag: 'adsbFab',
          icon: Icons.settings_input_antenna,
          label: 'Import from ADS-B',
          onPressed: () => _importAdsb(context),
        ),
        SpeedDialAction(
          heroTag: 'recordFab',
          icon: Icons.fiber_manual_record,
          label: 'Record',
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          onPressed: () => _openRecording(context),
        ),
      ],
      primaryIcon: Icons.add,
      primaryLabel: 'Add Flight',
      onPrimaryPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const FlightFormPage()),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.nickname});
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary,
                cs.primary.withValues(alpha: 0.8),
                cs.secondary,
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
                  color: cs.onPrimary.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.flight,
                  size: 120,
                  color: cs.onPrimary.withValues(alpha: 0.08),
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
                        color: cs.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nickname ?? 'Pilot',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: cs.onPrimary,
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
}

/// Shown while a flight is being recorded.
class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const PulsingDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording in progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to view recording',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openRecording(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.flightCount,
    required this.totalMinutes,
    required this.aircraftCount,
  });

  final int flightCount;
  final int totalMinutes;
  final int aircraftCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.flight_takeoff,
            value: '$flightCount',
            label: 'Total Flights',
            color: colors.info,
            onTap: () => _openFlights(context),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.schedule,
            value: DurationFormatter.hm(Duration(minutes: totalMinutes)),
            label: 'Flight Time',
            color: colors.success,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.airplanemode_active,
            value: '$aircraftCount',
            label: 'Aircraft',
            color: colors.warning,
            onTap: () => _openAircrafts(context),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}
