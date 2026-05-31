import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/flight_session.dart';
import 'replay_page.dart';

class FlightDetailPage extends StatelessWidget {
  final FlightSession flight;

  const FlightDetailPage({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(flight.title),
      ),
      body: ListView(
        children: [
          _buildHeroSection(context, flight),
          if (flight.departure != null || flight.arrival != null)
            _buildRouteSection(context, flight),
          _buildAltitudeChart(context, flight),
          _buildDetailsSection(context, flight),
          const SizedBox(height: 16),
          _buildReplayButton(context, flight),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, FlightSession flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            DateFormat('EEEE, MMMM d, y').format(flight.startTime),
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
                      ? '${flight.maxAltitude!.toStringAsFixed(0)} m'
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
                      ? '${(flight.totalDistance! / 1000).toStringAsFixed(1)} km'
                      : '--',
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
              value: '${_averageSpeed(flight)!.toStringAsFixed(1)} km/h',
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
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection(BuildContext context, FlightSession flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (flight.departure != null)
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      flight.departure!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            if (flight.departure != null && flight.arrival != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: cs.onSurfaceVariant,
                ),
              ),
            if (flight.arrival != null)
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.flight_land, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      flight.arrival!,
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

  Widget _buildAltitudeChart(BuildContext context, FlightSession flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spots = <FlSpot>[];
    final points = flight.points;

    if (points.length >= 2) {
      final firstTime = points.first.timestamp;
      final lastTime = points.last.timestamp;
      final durationMs = lastTime.difference(firstTime).inMilliseconds.toDouble();

      for (final point in points) {
        final elapsed = point.timestamp.difference(firstTime).inMilliseconds.toDouble();
        final x = durationMs > 0 ? elapsed / durationMs : 0.0;
        spots.add(FlSpot(x, point.altitude));
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
              'Altitude Profile',
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

  Widget _buildDetailsSection(BuildContext context, FlightSession flight) {
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
            _detailRow(theme, cs, 'Start', DateFormat('MMM d, y – HH:mm').format(flight.startTime)),
            if (flight.endTime != null)
              _detailRow(theme, cs, 'End', DateFormat('MMM d, y – HH:mm').format(flight.endTime!)),
            if (flight.aircraftType != null)
              _detailRow(theme, cs, 'Aircraft', flight.aircraftType!),
            _detailRow(theme, cs, 'Status', flight.status.name),
            _detailRow(theme, cs, 'Data Points', '${flight.points.length}'),
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

  Widget _buildReplayButton(BuildContext context, FlightSession flight) {
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

  double? _averageSpeed(FlightSession flight) {
    final speeds = flight.points
        .where((p) => p.speed != null)
        .map((p) => p.speed!)
        .toList();
    if (speeds.isEmpty) return null;
    final avg = speeds.reduce((a, b) => a + b) / speeds.length;
    return avg * 3.6;
  }
}
