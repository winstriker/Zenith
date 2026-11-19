import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/theme.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../repositories/pilot_profile_repository.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/hiding_chrome.dart';
import '../widgets/load_more.dart';
import '../widgets/page_header.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/simulator_card.dart';
import '../widgets/speed_dial_fab.dart';
import 'adsb_track_page.dart';
import 'aircrafts_page.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';
import 'flights_page.dart';
import 'recording_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// How many recent flights the list asks for; older ones load as it is
  /// scrolled to its end.
  int _limit = loadMorePageSize;

  /// The last flights loaded, shown while older ones load.
  List<FlightWithStats>? _flights;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tapping Home in the navigation bar again goes back to the top.
    ref.listen(tabReselectProvider, (_, next) {
      if (next?.tab == MainTab.home) scrollTabToTop(ref, _scroll);
    });
    final page = ref.watch(
      recordedFlightsPageProvider((limit: _limit, query: '', day: null)),
    );
    if (page.hasValue) _flights = page.value;
    final flights = _flights;
    final hasMore = flights != null && flights.length >= _limit;
    final flightCount = ref.watch(recordedFlightCountProvider);
    final gpsController = ref.watch(gpsTrackingControllerProvider.notifier);
    final aircraftList = ref.watch(aircraftListStreamProvider);
    final nickname = ref.watch(userNicknameProvider);
    final totalFlightTime = ref.watch(totalFlightTimeProvider);
    // Flight time logged before the app counts too.
    final previousMinutes = ref
        .watch(previousTotalsProvider)
        .time(LogbookTimeField.total)
        .inMinutes;
    final isRecording = gpsController.isTracking();

    return Scaffold(
      floatingActionButton: const HidingFabs(child: _HomeFabs()),
      body: StatusBarScrim(
        child: HideChromeOnScroll(
          child: LoadMoreScrollView(
            controller: _scroll,
            hasMore: hasMore,
            loading: !page.hasValue,
            onLoadMore: () => setState(() => _limit += loadMorePageSize),
            builder: (context, controller) => CustomScrollView(
              controller: controller,
              slivers: [
                PageHeader(
                  nickname ?? 'Pilot',
                  tab: MainTab.home,
                  overline: 'Welcome back,',
                  motif: (size, color) => Image.asset(
                    'assets/images/zenith_logo.png',
                    width: size,
                    height: size,
                    color: color,
                  ),
                ),
                if (isRecording)
                  const SliverToBoxAdapter(child: _RecordingBanner()),
                SliverToBoxAdapter(
                  child: _QuickStats(
                    flightCount: flightCount.when(
                      data: (val) => val,
                      error: (_, _) => -1,
                      loading: () => 0,
                    ),
                    totalMinutes: totalFlightTime.when(
                      data: (val) => val + previousMinutes,
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
                ...switch (flights) {
                  null when page.hasError => const [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.error_outline,
                        title: 'Error while loading flights',
                      ),
                    ),
                  ],
                  null => const [
                    SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  [] => const [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 40,
                        ),
                        child: EmptyState(
                          icon: Icons.flight,
                          title: 'No flights yet',
                          subtitle: 'Start recording your first flight!',
                          iconSize: 48,
                        ),
                      ),
                    ),
                  ],
                  _ => [
                    SliverList.builder(
                      itemCount: flights.length,
                      itemBuilder: (context, index) => FlightCard(
                        flight: flights[index],
                        onTap: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                            builder: (_) => FlightDetailPage(
                              flightId: flights[index].flight.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasMore)
                      const SliverToBoxAdapter(child: LoadMoreIndicator()),
                  ],
                },
                // Keeps the last flight clear of the FAB column and the nav bar.
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 136 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openFlights(BuildContext context) {
  Navigator.push(
    context,
    AppPageRoute<void>(builder: (_) => const FlightsPage()),
  );
}

void _openAircrafts(BuildContext context) {
  Navigator.push(
    context,
    AppPageRoute<void>(builder: (_) => const AircraftsPage()),
  );
}

void _openRecording(BuildContext context) {
  Navigator.push(
    context,
    AppPageRoute<void>(builder: (_) => const RecordingPage()),
  );
}

/// "Add Flight" FAB with a small "more" FAB above it that pops up the less
/// common ways to log a flight (simulator session, recording, ADS-B
/// import).
class _HomeFabs extends StatelessWidget {
  const _HomeFabs();

  Future<void> _importAdsb(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final imported = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => const AdsbTrackPage.import()),
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
          heroTag: 'simulatorFab',
          icon: simulatorIcon,
          label: 'Log simulator session',
          onPressed: () => Navigator.push(
            context,
            AppPageRoute<void>(
              builder: (_) => const FlightFormPage(simulator: true),
            ),
          ),
        ),
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
        AppPageRoute<void>(builder: (_) => const FlightFormPage()),
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
