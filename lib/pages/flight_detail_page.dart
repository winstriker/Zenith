import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    hide Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../providers/carto_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/unit_provider.dart';
import '../services/database.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/flight_card.dart';
import '../widgets/flight_rules_card.dart';
import '../widgets/info_row.dart';
import '../widgets/landings_card.dart';
import '../widgets/map_attribution.dart';
import '../widgets/remarks_card.dart';
import '../widgets/section_header.dart';
import 'flight_form_page.dart';
import 'replay_page.dart';

class FlightDetailPage extends ConsumerWidget {
  const FlightDetailPage({super.key, required this.flightId});
  final int flightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightAsync = ref.watch(flightByIdStreamProvider(flightId));

    return flightAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error loading flight: $e'))),
      data: (flight) {
        if (flight == null) {
          return const Scaffold(body: Center(child: Text('Flight not found')));
        }
        return _FlightDetailView(flight: flight);
      },
    );
  }
}

class _FlightDetailView extends StatelessWidget {
  const _FlightDetailView({required this.flight});
  final FlightWithStats flight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FlightFormPage(flightToEdit: flight),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _FlightMapCard(flight: flight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 270),
                    FlightCard(flight: flight, useOuterPadding: false),
                    const SizedBox(height: 12),
                    AircraftCard(
                      aircraft: flight.aircraftWithStats,
                      useOuterPadding: false,
                    ),
                    const SizedBox(height: 12),
                    LandingsCard(
                      approachType: flight.flight.approachType!,
                      nightLandings: flight.flight.nightLandings!,
                      dayLandings: flight.flight.dayLandings!,
                    ),
                    const SizedBox(height: 12),
                    FlightRulesCard(flightRules: flight.flight.flightRules!),
                    const SizedBox(height: 12),
                    if (flight.flight.remarks != null)
                      RemarksCard(initialValue: flight.flight.remarks!),
                    if (flight.dataPoints.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _AltitudeChartCard(points: flight.dataPoints),
                      const SizedBox(height: 12),
                      _FlightDetailsCard(flight: flight),
                      const SizedBox(height: 12),
                      _ReplayButtonCard(flight: flight),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Map card
// -----------------------------------------------------------------------------

class _FlightMapCard extends ConsumerStatefulWidget {
  const _FlightMapCard({required this.flight});
  final FlightWithStats flight;

  @override
  ConsumerState<_FlightMapCard> createState() => _FlightMapCardState();
}

class _FlightMapCardState extends ConsumerState<_FlightMapCard> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitMapBounds(FlightWithStats flight, bool hasData) {
    if (!_mapReady) return;

    LatLngBounds bounds;

    if (hasData && flight.dataPoints.length >= 2) {
      final points = flight.dataPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      bounds = LatLngBounds.fromPoints(points);
    } else {
      final depLat = flight.departure?.latitudeDeg;
      final depLon = flight.departure?.longitudeDeg;
      final arrLat = flight.arrival?.latitudeDeg;
      final arrLon = flight.arrival?.longitudeDeg;

      if (depLat != null &&
          depLon != null &&
          arrLat != null &&
          arrLon != null) {
        bounds = LatLngBounds(LatLng(depLat, depLon), LatLng(arrLat, arrLon));
      } else {
        bounds = LatLngBounds(
          LatLng(
            flight.departure!.latitudeDeg!,
            flight.departure!.longitudeDeg!,
          ),
          LatLng(
            flight.departure!.latitudeDeg!,
            flight.departure!.longitudeDeg!,
          ),
        );
      }
    }

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cartoStyle = ref.watch(cartoStyleProvider);

    final depLat = flight.departure?.latitudeDeg;
    final depLon = flight.departure?.longitudeDeg;
    final arrLat = flight.arrival?.latitudeDeg;
    final arrLon = flight.arrival?.longitudeDeg;

    final Widget content;
    if (depLat == null || depLon == null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 32,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No route data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } else {
      final points = flight.dataPoints;
      final hasData = points.isNotEmpty;
      content = cartoStyle.when(
        data: (style) {
          if (style == null) {
            return const Text(
              "Error: Style file is null. Are you sure your API key is correct?",
            );
          }
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(depLat, depLon),
              initialZoom: 10.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
              ),
              onMapReady: () {
                _mapReady = true;
                _fitMapBounds(flight, hasData);
              },
            ),
            children: [
              VectorTileLayer(
                tileProviders: style.providers,
                theme: style.theme,
                concurrency: 4,
                diskCacheTtl: const Duration(days: 30),
              ),
              const MapAttribution(),
              // Route polyline
              if (hasData && points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      strokeWidth: 3,
                      color: cs.primary,
                    ),
                  ],
                )
              else if (!hasData && arrLat != null && arrLon != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [LatLng(depLat, depLon), LatLng(arrLat, arrLon)],
                      strokeWidth: 3,
                      color: cs.primary,
                    ),
                  ],
                ),
              // Departure / Arrival markers
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(depLat, depLon),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: _RouteMarker(
                      icon: Icons.flight_takeoff,
                      color: cs.primary,
                      foreground: cs.onPrimary,
                    ),
                  ),
                  if (arrLat != null && arrLon != null)
                    Marker(
                      point: LatLng(arrLat, arrLon),
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: _RouteMarker(
                        icon: Icons.flight_land,
                        color: cs.error,
                        foreground: cs.onError,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load map style',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(height: 350, child: content),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({
    required this.icon,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: colors.onOverlay, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: foreground),
    );
  }
}

// -----------------------------------------------------------------------------
// Cards shown only for recorded flights
// -----------------------------------------------------------------------------

/// Icon badge + section title used at the top of the detail cards.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        SectionHeader(
          title: title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _AltitudeChartCard extends ConsumerWidget {
  const _AltitudeChartCard({required this.points});
  final List<FlightDataPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;
    final altFactor = isMetric ? 1.0 : 3.28084;
    final altUnit = isMetric ? 'm' : 'ft';

    final spots = <FlSpot>[];
    if (points.length >= 2) {
      final firstTime = points.first.timestamp;
      final durationMs = points.last.timestamp
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.show_chart,
              title: 'ALTITUDE PROFILE',
              trailing: Text(
                altUnit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spots.length >= 2
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
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
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: theme.textTheme.labelSmall,
                              ),
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
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: cs.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
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
}

class _FlightDetailsCard extends StatelessWidget {
  const _FlightDetailsCard({required this.flight});
  final FlightWithStats flight;

  static final _dateFormat = DateFormat('MMM d, y \u2013 HH:mm');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(icon: Icons.info_outline, title: 'FLIGHT DETAILS'),
            const SizedBox(height: 16),
            InfoRow(
              label: 'Start',
              value: _dateFormat.format(flight.flight.departureTime),
            ),
            if (flight.flight.arrivalTime != null)
              InfoRow(
                label: 'End',
                value: _dateFormat.format(flight.flight.arrivalTime!),
              ),
            InfoRow(
              label: 'Status',
              value: flight.flight.isRecording ? 'In Progress' : 'Recorded',
            ),
            InfoRow(label: 'Data Points', value: '${flight.dataPoints.length}'),
          ],
        ),
      ),
    );
  }
}

class _ReplayButtonCard extends StatelessWidget {
  const _ReplayButtonCard({required this.flight});
  final FlightWithStats flight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReplayPage(flight: flight),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_filled),
            label: const Text('View Replay'),
          ),
        ),
      ),
    );
  }
}
