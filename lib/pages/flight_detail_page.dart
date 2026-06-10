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
      appBar: AppBar(
        title: Text(flight.flight.title),
      ),
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

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final unitMode = ref.watch(unitProvider);

    final distanceKmVal = flight.totalDistance;
    final distanceKtsVal = flight.totalDistance != null ? flight.totalDistance! * 0.539957 : null;

    final maxAltMeterVal = flight.maxAltitude?.toDouble();
    final maxAltFeetVal = flight.maxAltitude != null ? flight.maxAltitude! * 3.28084 : null;

    final speedKmhVal = _averageSpeed(flight);
    final speedKnotsVal = _averageSpeed(flight) != null ? _averageSpeed(flight)! * 0.539957 : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.tertiary,
          ],
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
                child: Icon(
                  Icons.arrow_forward,
                  color: cs.onSurfaceVariant,
                ),
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

  Widget _buildAircraftSection(BuildContext context, WidgetRef ref, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final aircraftList = ref.watch(aircraftListProvider);
    final displayType = flight.aircraft?.type;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.airplanemode_active, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Aircraft', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAircraftPicker(flight, aircraftList),
                  icon: Icon(displayType != null ? Icons.edit : Icons.add, size: 16),
                  label: Text(displayType != null ? 'Change' : 'Add'),
                ),
              ],
            ),
            if (displayType != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayType,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (flight.aircraft?.tailNumber != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
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
                  if (flight.aircraft?.model != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      flight.aircraft!.model!,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No aircraft assigned',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAircraftPicker(FlightWithStats flight, List<AircraftWithStats> aircraftList) async {
    final aircraft = await showDialog<Aircraft>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Aircraft'),
        children: [
          ...aircraftList.map((aws) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, aws.aircraft),
            child: Row(
              children: [
                Icon(Icons.airplanemode_active, size: 18, color: Theme.of(ctx).colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  aws.aircraft.tailNumber != null
                      ? '${aws.aircraft.type} (${aws.aircraft.tailNumber})'
                      : aws.aircraft.type,
                ),
              ],
            ),
          )),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: Row(
              children: [
                Icon(Icons.remove_circle_outline, size: 18, color: Theme.of(ctx).colorScheme.error),
                const SizedBox(width: 12),
                const Text('None (remove aircraft)'),
              ],
            ),
          ),
        ],
      ),
    );

    final db = ref.read(databaseProvider);
    final flightService = ref.read(flightServiceProvider);
    await db.updateFlightAircraft(
      flight.flight.id,
      aircraftId: aircraft?.id,
    );
    await flightService.setFlightAircraft(
      flight.flight.id,
      aircraftId: aircraft?.id,
      aircraft: aircraft,
    );

    setState(() {
      _flight = flight.copyWith(
        aircraft: aircraft,
      );
    });

    ref.read(flightListProvider.notifier).refresh();
  }

  Widget _buildAltitudeChart(BuildContext context, WidgetRef ref, FlightWithStats flight) {
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
      final durationMs = lastTime.difference(firstTime).inMilliseconds.toDouble();

      for (final point in points) {
        final elapsed = point.timestamp.difference(firstTime).inMilliseconds.toDouble();
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
            Text(
              'Flight Details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _detailRow(theme, cs, 'Start', DateFormat('MMM d, y – HH:mm').format(flight.flight.departureTime)),
            if (flight.flight.arrivalTime != null)
              _detailRow(theme, cs, 'End', DateFormat('MMM d, y – HH:mm').format(flight.flight.arrivalTime!)),

            _detailRow(theme, cs, 'Status', flight.flight.isRecording ? 'inProgress' : 'recorded'),
            _detailRow(theme, cs, 'Data Points', '${flight.dataPoints.length}'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, ColorScheme cs, String label, String value) {
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
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
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
              MaterialPageRoute(
                builder: (_) => ReplayPage(flight: flight),
              ),
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
