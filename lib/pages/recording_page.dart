import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_page_route.dart';
import '../core/theme.dart';
import '../providers/flight_recorder_provider.dart';
import '../providers/unit_provider.dart';
import '../utils/duration_formatter.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/flight_route_layer.dart';
import '../widgets/map_attribution.dart';
import '../widgets/map_overlay.dart';
import '../widgets/pulsing_dot.dart';

/// Opens the recording page. When nothing is being recorded, asks first and
/// starts a recording.
Future<void> openRecording(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (ref.read(flightRecorderProvider) == null) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fiber_manual_record),
        title: const Text('Start recording?'),
        content: const Text(
          'Zenith will record your track with the GPS, also while the app '
          'is in the background, until you stop it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(flightRecorderProvider.notifier).start();
    } on RecordingException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: const SnackBarAction(
            label: 'Settings',
            onPressed: Geolocator.openAppSettings,
          ),
        ),
      );
      return;
    }
  }
  unawaited(
    navigator.push(AppPageRoute<void>(builder: (_) => const RecordingPage())),
  );
}

/// The flight being recorded on a full-screen map, with the live readings
/// and the button that stops it. Leaving the page doesn't stop recording.
class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  static final _timeFormat = DateFormat('HH:mm');

  final _mapController = MapController();
  bool _mapReady = false;

  /// Whether the map keeps the aircraft in view. Moving the map stops it.
  bool _follow = true;

  /// The bars over the map, hidden while the user moves the map.
  bool _overlayVisible = true;
  Timer? _overlayTimer;

  /// Ticks the elapsed time.
  late final Timer _clock;

  /// Kept to draw the last frames while the page closes after stopping.
  Recording? _recording;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    _overlayTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (!mapUserMoves.contains(event.source)) return;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _overlayVisible = true);
    });
    setState(() {
      _follow = false;
      _overlayVisible = false;
    });
  }

  void _recenter() {
    setState(() => _follow = true);
    final last = _recording?.path.lastOrNull;
    if (_mapReady && last != null) {
      _mapController.move(last, _mapController.camera.zoom);
    }
  }

  void _onRecordingChanged(Recording? previous, Recording? next) {
    final last = next?.path.lastOrNull;
    if (!_follow || !_mapReady || last == null) return;
    // The first fix zooms in from wherever the map was waiting.
    final zoom = (previous?.path.isEmpty ?? true)
        ? 15.0
        : _mapController.camera.zoom;
    _mapController.move(last, zoom);
  }

  Future<void> _stop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop recording?'),
        content: const Text(
          'The flight is saved as a temporary flight. Complete it from the '
          'flight list to add it to your logbook.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep recording'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final kept = await ref.read(flightRecorderProvider.notifier).stop();
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kept
              ? 'Saved as a temporary flight: tap it in the flight list to '
                    'complete it'
              : 'No position was recorded: nothing saved',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Recording?>(flightRecorderProvider, _onRecordingChanged);
    final recording = _recording =
        ref.watch(flightRecorderProvider) ?? _recording;
    if (recording == null) return const Scaffold();

    final cs = Theme.of(context).colorScheme;
    final overlay = context.appColors.overlay;
    final padding = MediaQuery.paddingOf(context);
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;
    final path = recording.path;
    final position = recording.position;
    final current = path.lastOrNull;
    final elapsed = DateTime.now().difference(recording.startedAt);
    final speed = position == null || position.speed < 0
        ? '--'
        : isMetric
        ? '${(position.speed * 3.6).round()} km/h'
        : '${(position.speed * 1.943844).round()} kts';
    final altitude = position == null
        ? '--'
        : isMetric
        ? '${position.altitude.round()} m'
        : '${(position.altitude * 3.28084).round()} ft';

    Widget fading(Widget child) =>
        FadingOverlay(visible: _overlayVisible, child: child);

    return Scaffold(
      backgroundColor: overlay,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: current ?? const LatLng(0, 0),
              initialZoom: current == null ? 2 : 15,
              onMapReady: () => _mapReady = true,
              onMapEvent: _onMapEvent,
            ),
            children: [
              const BaseMapLayer(),
              if (path.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(points: path, strokeWidth: 4, color: cs.primary),
                  ],
                ),
              if (current != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: current,
                      width: 48,
                      height: 48,
                      child: PlaneMarker(headingDeg: position?.heading ?? 0),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140 + padding.top,
            child: fading(
              MapScrim(
                colors: [
                  overlay.withValues(alpha: 0.7),
                  overlay.withValues(alpha: 0.3),
                  overlay.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Positioned(
            top: padding.top + 4,
            left: 4,
            right: 4,
            child: fading(
              MapTopBar(
                title: 'Recording',
                subtitle:
                    recording.error ??
                    (position == null
                        ? 'Waiting for GPS…'
                        : 'Since ${_timeFormat.format(recording.startedAt)} · '
                              '${path.length} positions'),
                trailing: _follow
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: context.appColors.onOverlay,
                        ),
                        tooltip: 'Follow aircraft',
                        onPressed: _recenter,
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 260 + padding.bottom,
            child: fading(
              MapScrim(
                colors: [
                  overlay.withValues(alpha: 0),
                  overlay.withValues(alpha: 0.5),
                  overlay.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 4,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                fading(
                  _RecordingPanel(
                    altitude: altitude,
                    speed: speed,
                    elapsed: elapsed,
                    onStop: _stop,
                  ),
                ),
                const SizedBox(height: 6),
                const MapAttributionLabel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.altitude,
    required this.speed,
    required this.elapsed,
    required this.onStop,
  });

  final String altitude;
  final String speed;
  final Duration elapsed;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Container(
      width: 1,
      height: 32,
      color: context.appColors.onOverlay.withValues(alpha: 0.1),
    );
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MapStatTile(label: 'ALT', value: altitude, icon: Icons.height),
              divider,
              MapStatTile(label: 'SPEED', value: speed, icon: Icons.speed),
              divider,
              MapStatTile(
                label: 'TIME',
                value: DurationFormatter.hms(elapsed),
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStop,
              icon: PulsingDot(size: 10, color: cs.onError),
              label: const Text('Stop recording'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
