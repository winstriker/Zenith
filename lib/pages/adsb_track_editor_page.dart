import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/fab_hero_tags.dart';
import '../models/flight_track.dart';
import '../providers/unit_provider.dart';
import '../services/adsb_track_source.dart';
import '../utils/duration_formatter.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/flight_route_layer.dart';
import '../widgets/map_attribution.dart';
import '../widgets/page_title.dart';

/// Cuts a flight out of a track that holds more than one, as when the
/// provider merged the way there and the way back. Pops the [AdsbFlight]
/// that is left.
class AdsbTrackEditorPage extends ConsumerStatefulWidget {
  const AdsbTrackEditorPage({
    super.key,
    required this.flight,
    required this.points,
  });

  final AdsbFlight flight;

  /// The whole track of [flight], in order. At least two points.
  final List<TrackPoint> points;

  @override
  ConsumerState<AdsbTrackEditorPage> createState() =>
      _AdsbTrackEditorPageState();
}

class _AdsbTrackEditorPageState extends ConsumerState<AdsbTrackEditorPage> {
  static const _maxSpots = 300;
  static final _time = DateFormat('HH:mm:ss');

  late final _path = [
    for (final p in widget.points) LatLng(p.latitude, p.longitude),
  ];
  late final _spots = [
    for (final (i, p) in TrackTools.thin(
      TrackTools.fillAltitudes(widget.points).indexed.toList(),
      _maxSpots,
      (entry) => entry.$2.altitude!,
    ))
      FlSpot(i.toDouble(), p.altitude!),
  ];

  /// The part kept, both ends included.
  int _first = 0;
  late int _last = widget.points.length - 1;

  /// Ignores anything that isn't a track: at least two points are kept.
  void _keep(int first, int last) {
    if (first < 0 || last >= widget.points.length || first >= last) return;
    setState(() {
      _first = first;
      _last = last;
    });
  }

  String _describe(TrackPoint point, bool isMetric) {
    final altitude = point.altitude;
    return [
      '${_time.format(point.time.toUtc())} UTC',
      if (point.onGround)
        'on the ground'
      else if (altitude != null)
        isMetric
            ? '${altitude.round()} m'
            : '${(altitude / TrackTools.feetToMetres).round()} ft',
    ].join(' · ');
  }

  /// One end of the part kept, with buttons to move it a point at a time:
  /// a finger on the slider can't.
  Widget _endTile(
    String label,
    IconData icon,
    int index,
    void Function(int index) move,
    bool isMetric,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(_describe(widget.points[index], isMetric)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '$label one position earlier',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => move(index - 1),
        ),
        IconButton(
          tooltip: '$label one position later',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => move(index + 1),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;
    final points = widget.points;
    final max = (points.length - 1).toDouble();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle(
            'Edit Track',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(_path),
                    padding: const EdgeInsets.all(32),
                    maxZoom: 14,
                  ),
                  // The page scrolls under the finger instead.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  const BaseMapLayer(),
                  const MapAttribution(),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _path,
                        strokeWidth: 3,
                        color: cs.primary.withValues(alpha: 0.25),
                      ),
                      Polyline(
                        points: _path.sublist(_first, _last + 1),
                        strokeWidth: 4,
                        color: cs.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _path[_first],
                        width: 24,
                        height: 24,
                        child: RouteMarker(
                          icon: Icons.flight_takeoff,
                          color: cs.primary,
                          foreground: cs.onPrimary,
                        ),
                      ),
                      Marker(
                        point: _path[_last],
                        width: 24,
                        height: 24,
                        child: RouteMarker(
                          icon: Icons.flight_land,
                          color: cs.error,
                          foreground: cs.onError,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Where the aircraft landed in between shows here: on the map, the
          // way back is drawn over the way there.
          Padding(
            // Lines the chart up with the track of the slider below.
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 96,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: max,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: [
                      VerticalRangeAnnotation(
                        x1: _first.toDouble(),
                        x2: _last.toDouble(),
                        color: cs.primary.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      color: cs.primary,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
                duration: Duration.zero,
              ),
            ),
          ),
          RangeSlider(
            max: max,
            values: RangeValues(_first.toDouble(), _last.toDouble()),
            semanticFormatterCallback: (value) =>
                _describe(points[value.round()], isMetric),
            onChanged: (values) =>
                _keep(values.start.round(), values.end.round()),
          ),
          _endTile(
            'Start',
            Icons.flight_takeoff,
            _first,
            (index) => _keep(index, _last),
            isMetric,
          ),
          _endTile(
            'End',
            Icons.flight_land,
            _last,
            (index) => _keep(_first, index),
            isMetric,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              widget.flight.trimmed(points, _first, _last),
            ),
            icon: const Icon(Icons.content_cut),
            label: Text(
              'Use this part · ${DurationFormatter.descriptive(points[_last].time.difference(points[_first].time))}',
            ),
          ),
        ],
      ),
    );
  }
}
