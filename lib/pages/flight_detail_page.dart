import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    hide Theme;
import 'package:logbook/widgets/aircraft_card.dart';
import 'package:logbook/widgets/flight_card.dart';
import 'package:logbook/widgets/flight_rules_card.dart';
import 'package:logbook/widgets/landings_card.dart';
import 'package:logbook/widgets/remarks_card.dart';
import '../providers/unit_provider.dart';
import '../providers/carto_provider.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import 'replay_page.dart';
import 'flight_form_page.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';

class FlightDetailPage extends ConsumerWidget {
  final int flightId;

  const FlightDetailPage({super.key, required this.flightId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightAsync = ref.watch(flightByIdProvider(flightId));

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

class _FlightDetailView extends ConsumerStatefulWidget {
  final FlightWithStats flight;

  const _FlightDetailView({required this.flight});

  @override
  ConsumerState<_FlightDetailView> createState() => _FlightDetailViewState();
}

class _FlightDetailViewState extends ConsumerState<_FlightDetailView> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  FlightWithStats get _flight => widget.flight;

  @override
  Widget build(BuildContext context) {
    final flight = _flight;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlightFormPage(flightToEdit: flight),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildMapCard(context, flight),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 270),
                    FlightCard(flight: flight, useOuterPadding: false),
                    const SizedBox(height: 12),
                    AircraftCard(
                      aircraft: flight.aircraft,
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
                    if (flight.flight.remarks != null) ...[
                      RemarksCard(initialValue: flight.flight.remarks!),
                    ],
                    if (flight.dataPoints.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAltitudeChart(context, ref, flight),
                      const SizedBox(height: 12),
                      _buildDetailsSection(context, flight),
                      const SizedBox(height: 12),
                      _buildReplayButton(context, flight),
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

  // ---------------------------------------------------------------------------
  // 1. Map Card
  // ---------------------------------------------------------------------------
  Widget _buildMapCard(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cartoStyle = ref.watch(cartoStyleProvider);

    final depLat = flight.departure?.latitudeDeg;
    final depLon = flight.departure?.longitudeDeg;
    final arrLat = flight.arrival?.latitudeDeg;
    final arrLon = flight.arrival?.longitudeDeg;

    if (depLat == null || depLon == null) {
      return Card(
        margin: EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 350,
          child: Center(
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
          ),
        ),
      );
    }

    final points = flight.dataPoints;
    final hasData = points.isNotEmpty;

    return Card(
      margin: EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 350,
        child: cartoStyle.when(
          data: (style) => FlutterMap(
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
                tileProviders: style!.providers,
                theme: style.theme,
                tileOffset: TileOffset.maplibre,
                concurrency: 4,
                diskCacheTtl: const Duration(days: 30),
                diskCacheMaximumSizeInBytes: 50 * 1024 * 1024,
              ),
              if (kReleaseMode) ...[
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                      ),
                      child: Text(
                        '© OpenStreetMap contributors,© CARTO',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flight_takeoff,
                        size: 12,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                  if (arrLat != null && arrLon != null)
                    Marker(
                      point: LatLng(arrLat, arrLon),
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flight_land,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load map style',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
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

  // ---------------------------------------------------------------------------
  // 7. Conditional: Altitude Profile
  // ---------------------------------------------------------------------------
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
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Icons.show_chart,
                    size: 18,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'ALTITUDE PROFILE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  altUnit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
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

  // ---------------------------------------------------------------------------
  // 7. Conditional: Flight Details
  // ---------------------------------------------------------------------------
  Widget _buildDetailsSection(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Icons.info_outline,
                    size: 18,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'FLIGHT DETAILS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              label: 'Start',
              value: DateFormat(
                'MMM d, y \u2013 HH:mm',
              ).format(flight.flight.departureTime),
              labelWidth: 100,
            ),
            if (flight.flight.arrivalTime != null)
              InfoRow(
                label: 'End',
                value: DateFormat(
                  'MMM d, y \u2013 HH:mm',
                ).format(flight.flight.arrivalTime!),
                labelWidth: 100,
              ),
            InfoRow(
              label: 'Status',
              value: flight.flight.isRecording ? 'In Progress' : 'Recorded',
              labelWidth: 100,
            ),
            InfoRow(
              label: 'Data Points',
              value: '${flight.dataPoints.length}',
              labelWidth: 100,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Conditional: View Replay Button
  // ---------------------------------------------------------------------------
  Widget _buildReplayButton(BuildContext context, FlightWithStats flight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
