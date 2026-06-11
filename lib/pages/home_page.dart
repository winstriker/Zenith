import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../providers/flight_providers.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import '../widgets/flight_card.dart';
import 'recording_page.dart';
import 'flight_detail_page.dart';
import 'flights_page.dart';
import 'aircrafts_page.dart';
import 'aircraft_detail_page.dart';
import 'aircraft_form_page.dart';

final _recentAirportsProvider = FutureProvider<List<Airport>>((ref) {
  final db = ref.read(databaseProvider);
  return db.getRecentAirports();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(flightListProvider);
    final isRecording = ref.watch(recordingStateProvider);
    final aircraftList = ref.watch(aircraftListProvider);
    final recentFlights = flights.take(3).toList();
    final theme = Theme.of(context);

    final totalMinutes = flights.fold<int>(0, (sum, f) {
      if (f.duration != null) return sum + f.duration!.inMinutes;
      return sum;
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(
            theme,
            flights.length,
            totalMinutes,
            aircraftList.length,
          ),
          SliverToBoxAdapter(
            child: _buildRecordingBanner(context, theme, isRecording),
          ),
          SliverToBoxAdapter(
            child: _buildQuickStats(
              context,
              theme,
              flights.length,
              totalMinutes,
              aircraftList.length,
            ),
          ),
          _buildSectionHeader(
            context,
            theme,
            'Recent Flights',
            Icons.flight,
            flights.length > 3 ? () => _openFlights(context) : null,
          ),
          if (recentFlights.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyFlights(theme))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => FlightCard(
                  flight: recentFlights[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FlightDetailPage(flight: recentFlights[index]),
                    ),
                  ),
                ),
                childCount: recentFlights.length,
              ),
            ),
          _buildAircraftSection(context, theme, aircraftList),
          _buildAirportsSection(context, theme, ref),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    int flightCount,
    int totalMinutes,
    int aircraftCount,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
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
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
                      'Pilot Logbook',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _headerStat(theme, '$flightCount', 'Flights'),
                        const SizedBox(width: 16),
                        _headerStat(
                          theme,
                          '${(totalMinutes / 60).toStringAsFixed(1)}h',
                          'Hours',
                        ),
                        const SizedBox(width: 16),
                        _headerStat(theme, '$aircraftCount', 'Aircraft'),
                      ],
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

  Widget _headerStat(ThemeData theme, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRecordingBanner(
    BuildContext context,
    ThemeData theme,
    bool isRecording,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                    child: const _PulsingDot(),
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
          : SizedBox(
              width: double.infinity,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
            '${(totalMinutes / 60).toStringAsFixed(1)}h',
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.flight,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No flights yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start recording your first flight!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAircraftSection(
    BuildContext context,
    ThemeData theme,
    List<AircraftWithStats> aircraftList,
  ) {
    if (aircraftList.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
                    MaterialPageRoute(builder: (_) => const AircraftsPage()),
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
                    MaterialPageRoute(builder: (_) => const AircraftsPage()),
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
                                    style: theme.textTheme.labelLarge?.copyWith(
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
                  final ac = aws.aircraft;
                  final hours = aws.totalFlightTime != null
                      ? '${(aws.totalFlightTime!.inMinutes / 60).toStringAsFixed(1)}h'
                      : null;
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
                            builder: (_) => AircraftDetailPage(aircraft: aws),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.surface,
                                theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.surface,
                                    theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
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
                                            color: theme
                                                .colorScheme
                                                .tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            airport.ident!,
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
