import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../providers/unit_provider.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import 'replay_page.dart';

class FlightDetailPage extends ConsumerStatefulWidget {
  final FlightWithStats flight;

  const FlightDetailPage({super.key, required this.flight});

  @override
  ConsumerState<FlightDetailPage> createState() => _FlightDetailPageState();
}

class _FlightDetailPageState extends ConsumerState<FlightDetailPage> {
  late FlightWithStats _flight;

  @override
  void initState() {
    super.initState();
    _flight = widget.flight;
  }

  @override
  Widget build(BuildContext context) {
    final flight = _flight;
    return Scaffold(
      appBar: AppBar(title: Text(flight.flight.title)),
      body: ListView(
        children: [
          _buildHeroSection(context, ref, flight),
          if (flight.departureIdent != null || flight.arrivalIdent != null)
            _buildRouteSection(context, flight),
          _buildAircraftSection(context, ref, flight),
          _buildAltitudeChart(context, ref, flight),
          _buildDetailsSection(context, flight),
          const SizedBox(height: 16),
          _buildReplayButton(context, flight),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    WidgetRef ref,
    FlightWithStats flight,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final unitMode = ref.watch(unitProvider);

    final distanceKmVal = flight.totalDistance;
    final distanceKtsVal = flight.totalDistance != null
        ? flight.totalDistance! * 0.539957
        : null;

    final maxAltMeterVal = flight.maxAltitude?.toDouble();
    final maxAltFeetVal = flight.maxAltitude != null
        ? flight.maxAltitude! * 3.28084
        : null;

    final speedKmhVal = _averageSpeed(flight);
    final speedKnotsVal = _averageSpeed(flight) != null
        ? _averageSpeed(flight)! * 0.539957
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, y').format(flight.flight.departureTime),
            style: textTheme.titleMedium?.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  context,
                  cs: cs,
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(flight.duration),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStat(
                  context,
                  cs: cs,
                  icon: Icons.trending_up,
                  label: 'Max Alt',
                  value: flight.maxAltitude != null
                      ? unitMode == MeasurementUnit.metric
                            ? '${maxAltMeterVal!.toStringAsFixed(0)} m'
                            : '${maxAltFeetVal!.toStringAsFixed(0)} ft'
                      : '--',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStat(
                  context,
                  cs: cs,
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: flight.totalDistance != null
                      ? unitMode == MeasurementUnit.metric
                            ? '${distanceKmVal!.toStringAsFixed(1)} km'
                            : '${distanceKtsVal!.toStringAsFixed(1)} nm'
                      : '--',
                  subtitle: flight.totalDistance != null
                      ? unitMode == MeasurementUnit.metric
                            ? '${distanceKtsVal!.toStringAsFixed(1)} kts'
                            : '${distanceKmVal!.toStringAsFixed(1)} km'
                      : null,
                ),
              ),
            ],
          ),
          if (_averageSpeed(flight) != null) ...[
            const SizedBox(height: 16),
            _buildStat(
              context,
              cs: cs,
              icon: Icons.speed,
              label: 'Avg Speed',
              value: unitMode == MeasurementUnit.metric
                  ? '${speedKmhVal!.toStringAsFixed(1)} km/h'
                  : '${speedKnotsVal!.toStringAsFixed(1)} knots',
              subtitle: unitMode == MeasurementUnit.metric
                  ? '${speedKnotsVal!.toStringAsFixed(1)} knots'
                  : '${speedKmhVal!.toStringAsFixed(1)} km/h',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.onPrimary.withValues(alpha: 0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (flight.departureIdent != null)
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      flight.departureIdent!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            if (flight.departureIdent != null && flight.arrivalIdent != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward, color: cs.onSurfaceVariant),
              ),
            if (flight.arrivalIdent != null)
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.flight_land, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      flight.arrivalIdent!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAircraftSection(
    BuildContext context,
    WidgetRef ref,
    FlightWithStats flight,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final aircraftList = ref.watch(aircraftListProvider);
    final displayType = flight.aircraft?.type;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.airplanemode_active,
                    size: 18,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Aircraft',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _showAircraftPicker(flight, aircraftList),
                  icon: Icon(
                    displayType != null ? Icons.swap_horiz : Icons.add,
                    size: 16,
                  ),
                  label: Text(displayType != null ? 'Change' : 'Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            if (displayType != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondaryContainer.withValues(alpha: 0.5),
                      cs.secondaryContainer.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.flight,
                        size: 24,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayType,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (flight.aircraft?.tailNumber != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    flight.aircraft!.tailNumber!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (flight.aircraft?.model != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              flight.aircraft!.model!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.airplanemode_active_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No aircraft assigned',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAircraftPicker(
    FlightWithStats flight,
    List<AircraftWithStats> aircraftList,
  ) async {
    final aircraft = await showModalBottomSheet<Aircraft>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select Aircraft',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (aircraftList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.airplanemode_active_outlined,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No aircraft available',
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add an aircraft in the Aircraft page first',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        ...aircraftList.map(
                          (aws) => _AircraftPickerTile(
                            aircraft: aws.aircraft,
                            onTap: () => Navigator.pop(ctx, aws.aircraft),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'None (remove aircraft)',
                                  style: Theme.of(ctx).textTheme.bodyLarge
                                      ?.copyWith(color: cs.onErrorContainer),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    final db = ref.read(databaseProvider);
    final flightService = ref.read(flightServiceProvider);
    await db.updateFlightAircraft(flight.flight.id, aircraftId: aircraft?.id);
    await flightService.setFlightAircraft(
      flight.flight.id,
      aircraftId: aircraft?.id,
      aircraft: aircraft,
    );

    setState(() {
      _flight = flight.copyWith(
        aircraft: aircraft,
        removeAircraft: aircraft == null,
      );
    });

    ref.read(flightListProvider.notifier).refresh();
  }

  Widget _buildAltitudeChart(
    BuildContext context,
    WidgetRef ref,
    FlightWithStats flight,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spots = <FlSpot>[];
    final points = flight.dataPoints;
    final unitMode = ref.watch(unitProvider);
    final altFactor = unitMode == MeasurementUnit.metric ? 1.0 : 3.28084;
    final altUnit = unitMode == MeasurementUnit.metric ? 'm' : 'ft';

    if (points.length >= 2) {
      final firstTime = points.first.timestamp;
      final lastTime = points.last.timestamp;
      final durationMs = lastTime
          .difference(firstTime)
          .inMilliseconds
          .toDouble();

      for (final point in points) {
        final elapsed = point.timestamp
            .difference(firstTime)
            .inMilliseconds
            .toDouble();
        final x = durationMs > 0 ? elapsed / durationMs : 0.0;
        spots.add(FlSpot(x, point.altitude * altFactor));
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Altitude Profile ($altUnit)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spots.length >= 2
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: theme.textTheme.labelSmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 0.25,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  '${(value * 100).toInt()}%',
                                  style: theme.textTheme.labelSmall,
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: cs.primary,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: cs.primary.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        'Not enough data points',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flight Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _detailRow(
              theme,
              cs,
              'Start',
              DateFormat(
                'MMM d, y – HH:mm',
              ).format(flight.flight.departureTime),
            ),
            if (flight.flight.arrivalTime != null)
              _detailRow(
                theme,
                cs,
                'End',
                DateFormat(
                  'MMM d, y – HH:mm',
                ).format(flight.flight.arrivalTime!),
              ),

            _detailRow(
              theme,
              cs,
              'Status',
              flight.flight.isRecording ? 'inProgress' : 'recorded',
            ),
            _detailRow(theme, cs, 'Data Points', '${flight.dataPoints.length}'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    ThemeData theme,
    ColorScheme cs,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildReplayButton(BuildContext context, FlightWithStats flight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReplayPage(flight: flight)),
            );
          },
          icon: const Icon(Icons.play_circle_filled),
          label: const Text('View Replay'),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double? _averageSpeed(FlightWithStats flight) {
    final speeds = flight.dataPoints
        .where((p) => p.speed != null)
        .map((p) => p.speed!)
        .toList();
    if (speeds.isEmpty) return null;
    final avg = speeds.reduce((a, b) => a + b) / speeds.length;
    return avg;
  }
}

class _AircraftPickerTile extends StatelessWidget {
  final Aircraft aircraft;
  final VoidCallback onTap;

  const _AircraftPickerTile({required this.aircraft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.airplanemode_active,
                size: 20,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          aircraft.type,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (aircraft.tailNumber != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            aircraft.tailNumber!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (aircraft.model != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      aircraft.model!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
