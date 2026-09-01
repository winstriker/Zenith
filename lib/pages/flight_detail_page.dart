import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:logbook/widgets/flight_card.dart';
import '../providers/unit_provider.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/carto_provider.dart';
import '../services/database.dart';
import 'aircraft_detail_page.dart';
import 'replay_page.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';
import '../widgets/gradient_card.dart';

class FlightDetailPage extends ConsumerStatefulWidget {
  final FlightWithStats flight;

  const FlightDetailPage({super.key, required this.flight});

  @override
  ConsumerState<FlightDetailPage> createState() => _FlightDetailPageState();
}

class _FlightDetailPageState extends ConsumerState<FlightDetailPage> {
  FlightWithStats? _cachedFlight;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  FlightWithStats get _flight => _cachedFlight ?? widget.flight;

  @override
  Widget build(BuildContext context) {
    final flightService = ref.watch(flightServiceProvider);
    final liveFlight = flightService.getSession(widget.flight.flight.id);
    final flight = liveFlight ?? _flight;

    return Scaffold(
      //appBar: AppBar(title: Text(flight.flight.title)),
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
                    _buildAircraftCard(context, ref, flight),
                    const SizedBox(height: 12),
                    _buildApproachCard(context, flight),
                    const SizedBox(height: 12),
                    _buildFlightRulesCard(context, flight),
                    const SizedBox(height: 12),
                    _buildRemarksCard(context, flight),
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
                tileOffset: TileOffset.DEFAULT,
                concurrency: 4,
                fileCacheTtl: const Duration(days: 30),
                fileCacheMaximumSizeInBytes: 50 * 1024 * 1024,
              ),
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
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Aircraft Card (display-only, form page style)
  // ---------------------------------------------------------------------------
  Widget _buildAircraftCard(
    BuildContext context,
    WidgetRef ref,
    FlightWithStats flight,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final aircraftList = ref.watch(aircraftListProvider);
    final aircraft = flight.aircraft;
    final aws = aircraft != null
        ? aircraftList.where((a) => a.id == aircraft.id).firstOrNull
        : null;

    if (aircraft != null && aws != null) {
      return BaseCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AircraftDetailPage(aircraft: aws)),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Icons.airplanemode_active,
                color: cs.onSecondaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aircraft.type,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (aircraft.model != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      aircraft.model!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (aircraft.tailNumber != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  aircraft.tailNumber!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      );
    }

    // No aircraft assigned
    return BaseCard(
      onTap: () => _showAircraftPicker(flight, aircraftList),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.airplanemode_active,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Select Aircraft',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Approach Card (display-only, form page style)
  // ---------------------------------------------------------------------------
  Widget _buildApproachCard(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final approachType = flight.flight.approachType ?? 'VISUAL';
    final nightLandings = flight.flight.nightLandings ?? 0;
    final dayLandings = flight.flight.dayLandings ?? 1;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flight_land, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'APPROACH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    approachType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildLandingCount(theme, cs, 'NIGHT', nightLandings),
            const SizedBox(width: 16),
            _buildLandingCount(theme, cs, 'DAY', dayLandings),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingCount(
    ThemeData theme,
    ColorScheme cs,
    String label,
    int value,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Flight Rules Card (display-only, form page style)
  // ---------------------------------------------------------------------------
  Widget _buildFlightRulesCard(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flightRules = flight.flight.flightRules ?? 'VFR';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.rule, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'FLIGHT RULES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flightRules,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Remarks Card (display-only, form page style)
  // ---------------------------------------------------------------------------
  Widget _buildRemarksCard(BuildContext context, FlightWithStats flight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remarks = flight.flight.remarks;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'REMARKS & ENDORSEMENTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                remarks != null && remarks.isNotEmpty ? remarks : 'No remarks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: remarks != null && remarks.isNotEmpty
                      ? null
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
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

  // ---------------------------------------------------------------------------
  // Aircraft picker bottom sheet
  // ---------------------------------------------------------------------------
  Future<void> _showAircraftPicker(
    FlightWithStats flight,
    List<AircraftWithStats> aircraftList,
  ) async {
    final currentlySelected = flight.aircraft;
    var didSelectRemove = false;

    final aircraft = await showModalBottomSheet<Aircraft>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final theme = Theme.of(ctx);
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
                  child: Row(
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
                        'Select Aircraft',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (aircraftList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.airplanemode_active_outlined,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No aircraft available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add an aircraft in the Aircraft page first',
                            style: theme.textTheme.bodySmall?.copyWith(
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
                        const SizedBox(height: 4),
                        ...aircraftList.map(
                          (aws) => _AircraftPickerTile(
                            aircraft: aws,
                            isSelected: currentlySelected?.id == aws.id,
                            onTap: () => Navigator.pop(ctx, aws),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(height: 1),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            didSelectRemove = true;
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 22,
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'None (remove aircraft)',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (aircraft == null && !didSelectRemove) return;

    final flightService = ref.read(flightServiceProvider);
    await flightService.setFlightAircraft(
      flight.flight.id,
      aircraftId: aircraft?.id,
      aircraft: aircraft,
    );

    if (aircraft != null) {
      setState(() {
        _cachedFlight = flight.copyWith(
          aircraft: aircraft,
          removeAircraft: false,
        );
      });
    } else {
      setState(() {
        _cachedFlight = flight.copyWith(aircraft: null, removeAircraft: true);
      });
    }

    ref.read(flightListProvider.notifier).refresh();
  }
}

// ---------------------------------------------------------------------------
// Aircraft picker tile
// ---------------------------------------------------------------------------
class _AircraftPickerTile extends StatelessWidget {
  final Aircraft aircraft;
  final bool isSelected;
  final VoidCallback onTap;

  const _AircraftPickerTile({
    required this.aircraft,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: isSelected
            ? cs.secondaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? cs.secondary.withValues(alpha: 0.6)
                    : Colors.transparent,
                width: isSelected ? 1.5 : 0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.secondaryContainer,
                        cs.secondaryContainer.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? Icons.flight : Icons.airplanemode_active,
                    size: 22,
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
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                aircraft.tailNumber!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (aircraft.model != null) ...[
                        const SizedBox(height: 3),
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
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 16, color: cs.onSecondary),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
