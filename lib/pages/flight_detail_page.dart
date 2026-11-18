import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../core/theme.dart';
import '../models/flight_track.dart';
import '../models/logbook_entry.dart';
import '../providers/adsb_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/person_providers.dart';
import '../providers/unit_provider.dart';
import '../repositories/flight_repository.dart';
import '../services/adsb_track_source.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/crew_card.dart';
import '../widgets/flight_card.dart';
import '../widgets/flight_rules_card.dart';
import '../widgets/info_row.dart';
import '../widgets/landings_card.dart';
import '../widgets/map_attribution.dart';
import '../widgets/page_title.dart';
import '../widgets/remarks_card.dart';
import '../widgets/section_header.dart';
import '../widgets/simulator_card.dart';
import '../widgets/speed_dial_fab.dart';
import 'adsb_track_page.dart';
import 'flight_form_page.dart';
import 'logbook_overrides_page.dart';
import 'person_detail_page.dart';
import 'replay_page.dart';
import 'simulator_detail_page.dart';

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
        return _FlightDetailView(listed: flight);
      },
    );
  }
}

/// Height of the map at the top of the page, and where the cards start:
/// over its lower part.
const double _mapHeight = 350;
const double _cardsTop = 270;

class _FlightDetailView extends ConsumerWidget {
  const _FlightDetailView({required this.listed});

  /// The flight as the lists have it: without its track.
  final FlightWithStats listed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The track is only loaded here, where it is drawn. The same list comes
    // back until the track changes, which the map and the chart rely on to
    // not start over at every rebuild.
    final track = ref.watch(flightTrackProvider(listed.flight.id));
    final points = track.value ?? const <FlightDataPoint>[];
    final flight = points.isEmpty
        ? listed
        : listed.copyWith(dataPoints: points);
    final approachType = flight.flight.approachType;
    final flightRules = flight.flight.flightRules;
    final signatureName = flight.flight.signatureFile;
    final signatureDir = ref.watch(signatureDirectoryProvider).value;
    final signature = signatureName == null || signatureDir == null
        ? null
        : File('${signatureDir.path}/$signatureName');

    final isSession = flight.isSimulatorSession;
    final simulator = flight.simulator;
    final details = <Widget>[
      FlightCard(
        flight: flight,
        useOuterPadding: false,
        totalTimeOverride: flight
            .flight
            .logbookOverrides
            ?.times[isSession ? LogbookTimeField.fstd : LogbookTimeField.total],
      ),
      const SizedBox(height: 12),
      if (isSession)
        SimulatorCard(
          simulator: simulator,
          useOuterPadding: false,
          onTap: simulator == null
              ? null
              : () => Navigator.of(context).push(
                  AppPageRoute<void>(
                    builder: (_) =>
                        SimulatorDetailPage(simulatorId: simulator.id),
                  ),
                ),
        )
      else
        AircraftCard(
          aircraft: flight.aircraftWithStats,
          useOuterPadding: false,
        ),
      // A flight the app recorded has none of these until it is edited.
      if (approachType != null) ...[
        const SizedBox(height: 12),
        LandingsCard(
          approachType: approachType,
          nightLandings: flight.flight.nightLandings ?? 0,
          dayLandings: flight.flight.dayLandings ?? 0,
          mountainLandings: switch (flight.flight.mountainLandings) {
            final n? when n > 0 => n,
            _ => null,
          },
        ),
      ],
      if (flightRules != null && !isSession) ...[
        const SizedBox(height: 12),
        _FlightRulesTimesCard(flight: flight),
      ],
      const SizedBox(height: 12),
      _FlightCrewCard(flight: flight.flight),
      if (flight.flight.remarks != null || signature != null) ...[
        const SizedBox(height: 12),
        RemarksCard(
          initialValue: flight.flight.remarks ?? '',
          signature: signature,
        ),
      ],
      if (flight.dataPoints.isNotEmpty) ...[
        const SizedBox(height: 12),
        _AltitudeChartCard(points: flight.dataPoints),
        const SizedBox(height: 12),
        _FlightDetailsCard(flight: flight),
        const SizedBox(height: 12),
        _ReplayButtonCard(flight: flight),
      ] else if (track.hasValue &&
          !flight.flight.isRecording &&
          !isSession) ...[
        const SizedBox(height: 12),
        _NoTrackCard(flight: flight),
      ],
    ];

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: SpeedDialFab(
          actions: [
            SpeedDialAction(
              heroTag: 'logbookOverridesFab',
              icon: Icons.edit_note,
              label: 'Logbook overrides',
              onPressed: () => _openOverrides(context, flight),
            ),
          ],
          primaryIcon: Icons.edit,
          primaryLabel: 'Edit',
          onPrimaryPressed: () => Navigator.of(context).push(
            AppPageRoute<void>(
              builder: (_) => FlightFormPage(flightToEdit: flight),
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (isSession) ...[
              const PageTitle('Simulator Session', belowCloseButton: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: details),
              ),
            ] else
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _FlightMapCard(flight: flight),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: _cardsTop),
                        ...details,
                      ],
                    ),
                  ),
                ],
              ),
            // Room for the last card to scroll clear of the Edit button.
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

void _openOverrides(BuildContext context, FlightWithStats flight) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => LogbookOverridesPage(flight: flight)),
  );
}

// -----------------------------------------------------------------------------
// Flight rules
// -----------------------------------------------------------------------------

/// Flight rules with the IFR, VFR and night time logged for the flight,
/// overrides included. A value that differs from the flight's own (directly
/// overridden, or following an overridden total) is marked.
class _FlightRulesTimesCard extends StatelessWidget {
  const _FlightRulesTimesCard({required this.flight});
  final FlightWithStats flight;

  @override
  Widget build(BuildContext context) {
    final f = flight.flight;
    final original = LogbookEntry.of(flight, overrides: LogbookOverrides.empty);
    final logged = LogbookEntry.of(flight);
    final duration = flight.duration;
    final blockKnown = duration != null && !duration.isNegative;

    // What a value is, from the flight alone or with the overrides: null
    // when it isn't known (and not overridden).
    Duration? total(LogbookEntry e) =>
        blockKnown || e.isOverridden(LogbookTimeField.total)
        ? e.time(LogbookTimeField.total)
        : null;
    Duration? ifr(LogbookEntry e) =>
        e.isOverridden(LogbookTimeField.ifr) ||
            FlightRulesKind.of(f.flightRules) != FlightRulesKind.mixed ||
            f.instrumentMinutes != null
        ? e.time(LogbookTimeField.ifr)
        : null;
    Duration? vfr(LogbookEntry e) {
      final t = total(e);
      final i = ifr(e);
      return t == null || i == null ? null : t - i;
    }

    Duration? night(LogbookEntry e) =>
        e.isOverridden(LogbookTimeField.night) || f.nightMinutes != null
        ? e.time(LogbookTimeField.night)
        : null;

    bool changed(LogbookTimeField field, Duration? Function(LogbookEntry) of) =>
        logged.isOverridden(field) || of(logged) != of(original);

    return FlightRulesCard(
      flightRules: f.flightRules!,
      instrumentTime: ifr(logged),
      visualTime: vfr(logged),
      nightTime: night(logged),
      instrumentOverridden: changed(LogbookTimeField.ifr, ifr),
      visualOverridden: vfr(logged) != vfr(original),
      nightOverridden: changed(LogbookTimeField.night, night),
    );
  }
}

// -----------------------------------------------------------------------------
// Crew card
// -----------------------------------------------------------------------------

/// Read-only crew. Hidden for flights with neither a role nor crew (e.g.
/// recorded flights never edited). Tapping a person opens their profile.
class _FlightCrewCard extends ConsumerWidget {
  const _FlightCrewCard({required this.flight});
  final Flight flight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crew = ref.watch(flightCrewProvider(flight.id)).value ?? const [];
    final pilotRole = flight.pilotRole;
    if (pilotRole == null && crew.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CrewCard.readOnly(
        pilotRole: CrewRole.fromString(pilotRole ?? CrewRole.pic.name),
        crewMembers: crew,
        onCrewMemberTap: (member) => Navigator.push(
          context,
          AppPageRoute<void>(
            builder: (_) => PersonDetailPage(personId: member.person.id),
          ),
        ),
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

  /// How far the cards below come up over the map.
  static const _cardOverlap = _mapHeight - _cardsTop;

  /// The track as the map wants it. Worked out once per track, not at every
  /// rebuild: a track has thousands of points.
  late List<LatLng> _path = _pathOf(widget.flight);

  static List<LatLng> _pathOf(FlightWithStats flight) => [
    for (final p in flight.dataPoints) LatLng(p.latitude, p.longitude),
  ];

  static LatLng? _position(Airport? airport) {
    final lat = airport?.latitudeDeg;
    final lon = airport?.longitudeDeg;
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }

  @override
  void didUpdateWidget(_FlightMapCard old) {
    super.didUpdateWidget(old);
    // The track arrives after the page opens, and changes when one is
    // fetched or removed.
    if (!identical(old.flight.dataPoints, widget.flight.dataPoints)) {
      _path = _pathOf(widget.flight);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Everything the map should show: the track when there is one, the
  /// airports otherwise.
  List<LatLng> get _extent => _path.length >= 2
      ? _path
      : [
          ?_position(widget.flight.departure),
          ?_position(widget.flight.arrival),
        ];

  void _fitMapBounds() {
    if (!_mapReady || !mounted) return;
    final extent = _extent;
    if (extent.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(extent);
    if (bounds.southWest == bounds.northEast) {
      // One spot (a flight back to where it left from, without a track):
      // there is nothing to fit.
      _mapController.move(bounds.southWest, 10);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        // Clear of the status bar and close button at the top, and of the
        // flight card, which is drawn over the bottom of the map.
        padding: EdgeInsets.fromLTRB(
          40,
          MediaQuery.paddingOf(context).top + 24,
          40,
          _cardOverlap + 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasTrack = _path.length >= 2;
    // A recorded flight may have no airports: its track still has two ends.
    final start =
        _position(flight.departure) ?? (hasTrack ? _path.first : null);
    final end = _position(flight.arrival) ?? (hasTrack ? _path.last : null);

    final Widget content;
    if (start == null) {
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
      content = FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: start,
          initialZoom: 10.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
          ),
          onMapReady: () {
            _mapReady = true;
            _fitMapBounds();
          },
        ),
        children: [
          const BaseMapLayer(),
          const MapAttribution(),
          // The track flown, or a straight line between the airports.
          if (hasTrack)
            PolylineLayer(
              polylines: [
                Polyline(points: _path, strokeWidth: 3, color: cs.primary),
              ],
            )
          else if (end != null)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [start, end],
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ],
            ),
          // Departure / Arrival markers
          MarkerLayer(
            markers: [
              Marker(
                point: start,
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: _RouteMarker(
                  icon: Icons.flight_takeoff,
                  color: cs.primary,
                  foreground: cs.onPrimary,
                ),
              ),
              if (end != null)
                Marker(
                  point: end,
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
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(height: _mapHeight, child: content),
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

  static const _maxSpots = 300;

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

      // A track has thousands of points, the chart a few hundred pixels:
      // drawing them all is slow and looks no different.
      for (final point in TrackTools.thin(
        points,
        _maxSpots,
        (p) => p.altitude,
      )) {
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
                              getTitlesWidget: (value, meta) {
                                // The lowest and highest values get a label
                                // of their own, which lands on top of the
                                // nearest round one.
                                if (value == meta.min || value == meta.max) {
                                  return const SizedBox.shrink();
                                }
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
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            preventCurveOverShooting: true,
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

class _FlightDetailsCard extends ConsumerWidget {
  const _FlightDetailsCard({required this.flight});
  final FlightWithStats flight;

  static final _dateFormat = DateFormat('MMM d, y – HH:mm');
  static final _number = NumberFormat.decimalPattern();

  Future<void> _removeTrack(BuildContext context, WidgetRef ref) async {
    final recorded = flight.flight.trackSource == null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Track'),
        content: Text(
          recorded
              ? 'The track the app recorded for this flight is deleted for '
                    "good: it can't be recorded again. The flight itself "
                    'stays in the logbook.'
              : 'The track is deleted. The flight itself stays in the '
                    'logbook, and the track can be fetched again while the '
                    'provider still has it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(flightRepositoryProvider).deleteTrack(flight.flight.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;
    final provider = AdsbProvider.byId(flight.flight.trackSource);
    final distance = flight.totalDistance;
    final maxAltitude = flight.maxAltitude;

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
              value: flight.flight.isRecording
                  ? 'In Progress'
                  : provider == null
                  ? 'Recorded'
                  : 'ADS-B track',
            ),
            InfoRow(
              label: 'Track',
              value: provider?.label ?? 'Recorded by this device',
            ),
            if (distance != null)
              InfoRow(
                label: 'Distance',
                value: isMetric
                    ? '${_number.format(distance.round())} km'
                    : '${_number.format((distance / 1.852).round())} NM',
              ),
            if (maxAltitude != null)
              InfoRow(
                label: 'Max Altitude',
                value: isMetric
                    ? '${_number.format(maxAltitude)} m'
                    : '${_number.format((maxAltitude * 3.28084).round())} ft',
              ),
            InfoRow(
              label: 'Data Points',
              value: _number.format(flight.dataPoints.length),
            ),
            if (provider != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  provider.attribution,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (!flight.flight.isRecording) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _findAdsbTrack(context, flight),
                    icon: const Icon(Icons.radar, size: 18),
                    label: Text(
                      provider == null
                          ? 'Use ADS-B track'
                          : 'Fetch ADS-B track again',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _removeTrack(context, ref),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove track'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens the search for the flight's track on the ADS-B providers, and says
/// so when one was saved.
Future<void> _findAdsbTrack(
  BuildContext context,
  FlightWithStats flight,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await Navigator.of(
    context,
  ).push<int>(AppPageRoute(builder: (_) => AdsbTrackPage(flight: flight)));
  if (saved == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Track saved · ${NumberFormat.decimalPattern().format(saved)} '
        'positions',
      ),
    ),
  );
}

/// Shown instead of the track cards for a flight that has no track: the way
/// to fetch one.
class _NoTrackCard extends StatelessWidget {
  const _NoTrackCard({required this.flight});
  final FlightWithStats flight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(icon: Icons.route, title: 'TRACK'),
            const SizedBox(height: 12),
            Text(
              'This flight has no track. If its aircraft was seen by ADS-B '
              'receivers, the track it flew can be fetched: the route on '
              'the map, the altitude profile and the replay.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _findAdsbTrack(context, flight),
                icon: const Icon(Icons.radar),
                label: const Text('Find ADS-B Track'),
              ),
            ),
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
                AppPageRoute<void>(builder: (_) => ReplayPage(flight: flight)),
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
