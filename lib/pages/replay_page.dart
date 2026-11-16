import 'dart:math' show sin, cos, atan2;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../providers/unit_provider.dart';
import '../services/adsb_track_source.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/map_attribution.dart';

class ReplayPage extends ConsumerStatefulWidget {
  const ReplayPage({super.key, required this.flight});
  final FlightWithStats flight;

  @override
  ConsumerState<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends ConsumerState<ReplayPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Animation controller for smooth 60fps playback. Its value is how far
  // into the flight the replay is, from 0 to 1.
  late final AnimationController _animationController;

  // Flight data (pre-computed)
  late final List<FlightDataPoint> _points;
  late final List<LatLng> _pathPoints;

  /// Seconds from the first position to each one. The replay follows the
  /// clock of the flight: the aircraft moves at the speed it flew, and
  /// waits where it waited.
  late final List<double> _elapsed;

  /// From the first position to the last.
  late final Duration _trackDuration;

  // Current state (updated by animation)
  LatLng? _currentPosition;
  double _currentAltitude = 0;
  double? _currentSpeed;
  double? _currentHeading;
  int _currentSegmentIndex = 0;

  // Playback state: how many times faster than the flight.
  late double _speed;
  bool _mapReady = false;

  /// Without a faster choice, a replay would last as long as the flight.
  static const _speeds = [1.0, 10.0, 30.0, 100.0];

  /// What the replay of a whole flight should about last to start with.
  static const _comfortable = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _initFlightData();
    _animationController = AnimationController(
      vsync: this,
      duration: _playbackDuration,
    );
    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  void _initFlightData() {
    _points = widget.flight.dataPoints;
    _pathPoints = [for (final p in _points) LatLng(p.latitude, p.longitude)];

    var elapsed = <double>[
      for (final p in _points)
        p.timestamp.difference(_points.first.timestamp).inMilliseconds / 1000,
    ];
    if (_points.length >= 2 && elapsed.last <= 0) {
      // Positions that all carry the same time: spread them evenly.
      elapsed = [
        for (var i = 0; i < _points.length; i++)
          30.0 * i / (_points.length - 1),
      ];
    }
    _elapsed = elapsed;
    _trackDuration = Duration(
      milliseconds: elapsed.isEmpty ? 0 : (elapsed.last * 1000).round(),
    );
    // The slowest speed that shows the whole flight in a couple of minutes.
    _speed = _speeds.firstWhere(
      (speed) => _trackDuration * (1 / speed) <= _comfortable,
      orElse: () => _speeds.last,
    );

    _currentPosition = _pathPoints.isNotEmpty ? _pathPoints.first : null;
    if (_points.isNotEmpty) {
      _currentAltitude = _points.first.altitude.toDouble();
      _currentSpeed = _points.first.speed;
      _currentHeading = _points.first.heading;
    }
  }

  /// How long the replay lasts at the chosen speed.
  Duration get _playbackDuration {
    final duration = _trackDuration * (1 / _speed);
    return duration > Duration.zero
        ? duration
        : const Duration(milliseconds: 1);
  }

  void _onAnimationTick() => _updateCurrentPoint(_animationController.value);

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _animationController.reset());
    }
  }

  void _updateCurrentPoint(double progress) {
    if (_pathPoints.isEmpty) return;
    if (_pathPoints.length == 1) {
      _currentPosition = _pathPoints.first;
      return;
    }

    final target = progress.clamp(0.0, 1.0) * _elapsed.last;

    // Binary search for the last position not after the target time
    // (O(log n) instead of O(n)).
    var low = 0;
    var high = _elapsed.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_elapsed[mid] <= target) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    _currentSegmentIndex = low.clamp(0, _elapsed.length - 2);

    final segStart = _elapsed[_currentSegmentIndex];
    final segEnd = _elapsed[_currentSegmentIndex + 1];
    final t = segEnd > segStart
        ? ((target - segStart) / (segEnd - segStart)).clamp(0.0, 1.0)
        : 0.0;

    final p1 = _pathPoints[_currentSegmentIndex];
    final p2 = _pathPoints[_currentSegmentIndex + 1];
    _currentPosition = LatLng(
      p1.latitude + (p2.latitude - p1.latitude) * t,
      p1.longitude + (p2.longitude - p1.longitude) * t,
    );

    // Interpolate altitude, speed, heading from data points
    final dp1 = _points[_currentSegmentIndex];
    final dp2 = _points[_currentSegmentIndex + 1];
    _currentAltitude = dp1.altitude + (dp2.altitude - dp1.altitude) * t;
    _currentSpeed = dp1.speed != null && dp2.speed != null
        ? dp1.speed! + (dp2.speed! - dp1.speed!) * t
        : (dp1.speed ?? dp2.speed);
    // Standing still there is no way it is going: keep the last heading.
    if (p1 != p2) _currentHeading = _computeBearing(dp1, dp2);
  }

  double _computeBearing(FlightDataPoint p1, FlightDataPoint p2) {
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  void _togglePlayback() {
    if (_pathPoints.length < 2) return;
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _animationController.duration = _playbackDuration;
      _animationController.forward(
        from: _animationController.value >= 1.0
            ? 0.0
            : _animationController.value,
      );
    }
    setState(() {});
  }

  void _setSpeed(double speed) {
    final wasPlaying = _animationController.isAnimating;
    setState(() => _speed = speed);
    // The speed only changes how fast the flight goes by, not where in it
    // the replay is.
    _animationController.duration = _playbackDuration;
    if (wasPlaying) {
      _animationController.forward(from: _animationController.value);
    }
  }

  void _onSliderChanged(double value) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    // Moving the controller updates the position through its listener.
    _animationController.value = value;
    setState(() {});
  }

  String _formatAltitude(double meters, bool isMetric) {
    if (isMetric) return '${meters.round()} m';
    final feet = meters * 3.28084;
    return '${feet.round()} ft';
  }

  String _formatSpeed(double? speed, bool isMetric) {
    if (speed == null) return '--';
    if (isMetric) return '${speed.round()} km/h';
    final knots = speed * 0.539957;
    return '${knots.round()} kts';
  }

  List<LatLng> _buildTrailPoints() {
    if (_animationController.value <= 0 || _currentPosition == null) return [];
    final idx = _currentSegmentIndex;
    return [..._pathPoints.sublist(0, idx + 1), _currentPosition!];
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.removeStatusListener(_onAnimationStatusChanged);
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _mapReady = true;
    _fitMapBounds();
  }

  /// Shows the whole flight, clear of the bars drawn over the map.
  void _fitMapBounds() {
    if (!_mapReady || _pathPoints.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_pathPoints);
    if (bounds.southWest == bounds.northEast) {
      _mapController.move(_pathPoints.first, 13.0);
    } else {
      final padding = MediaQuery.paddingOf(context);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.fromLTRB(
            40,
            padding.top + 110,
            40,
            padding.bottom + 270,
          ),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          _mapController.camera.center,
          _mapController.camera.zoom + 0.000001,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overlay = context.appColors.overlay;
    final padding = MediaQuery.paddingOf(context);
    final points = _points;
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;
    // An ADS-B track is shown with the credit its provider asks for.
    final provider = AdsbProvider.byId(widget.flight.flight.trackSource);

    return Scaffold(
      backgroundColor: overlay,
      body: Stack(
        children: [
          // Map - static, doesn't rebuild on animation
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: points.isNotEmpty
                  ? LatLng(points.first.latitude, points.first.longitude)
                  : const LatLng(51.5, -0.09),
              initialZoom: 10.0,
              onMapReady: _onMapReady,
            ),
            children: [
              const BaseMapLayer(),
              // Static full path
              if (_pathPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _pathPoints,
                      strokeWidth: 3,
                      color: cs.primary.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              // Animated trail + plane marker
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  if (_pathPoints.length < 2 || _currentPosition == null) {
                    return const SizedBox.shrink();
                  }
                  final trail = _buildTrailPoints();
                  return Stack(
                    children: [
                      // At the very start nothing has been flown yet, and a
                      // polyline can't be empty.
                      if (trail.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: trail,
                              strokeWidth: 4,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: _PlaneMarker(
                              headingDeg: _currentHeading ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // Top gradient overlay (static)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140 + padding.top,
            child: _ScrimGradient(
              colors: [
                overlay.withValues(alpha: 0.7),
                overlay.withValues(alpha: 0.3),
                overlay.withValues(alpha: 0),
              ],
            ),
          ),

          // Top bar with flight info and (animated) speed
          Positioned(
            top: padding.top + 4,
            left: 4,
            right: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReplayTopBar(
                  title: widget.flight.flight.title,
                  pointsCount: _points.length,
                  speedBadge: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) => _currentSpeed == null
                        ? const SizedBox.shrink()
                        : _SpeedBadge(
                            value: _formatSpeed(_currentSpeed, isMetric),
                          ),
                  ),
                ),
                // The top-left corner of the map is under the top bar.
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: MapAttributionLabel(),
                ),
                if (provider != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      provider.attribution,
                      style: TextStyle(
                        color: context.appColors.onOverlay.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom gradient overlay (static)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 260 + padding.bottom,
            child: _ScrimGradient(
              colors: [
                overlay.withValues(alpha: 0),
                overlay.withValues(alpha: 0.5),
                overlay.withValues(alpha: 0.8),
              ],
            ),
          ),

          // Control panel - animated
          Positioned(
            bottom: padding.bottom + 16,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                final elapsed = _trackDuration * _animationController.value;
                return _ReplayControlPanel(
                  progress: _animationController.value,
                  elapsed: elapsed,
                  remaining: _trackDuration - elapsed,
                  altitude: _formatAltitude(_currentAltitude, isMetric),
                  speed: _formatSpeed(_currentSpeed, isMetric),
                  isPlaying: _animationController.isAnimating,
                  playbackSpeed: _speed,
                  playbackSpeeds: _speeds,
                  onSeek: _onSliderChanged,
                  onTogglePlayback: _togglePlayback,
                  onPlaybackSpeedChanged: _setSpeed,
                );
              },
            ),
          ),

          // Empty state for insufficient data
          if (_pathPoints.length < 2)
            _ReplayEmptyState(
              message: _pathPoints.isEmpty
                  ? 'No flight data available'
                  : 'Not enough points to replay',
            ),
        ],
      ),
    );
  }
}

class _ScrimGradient extends StatelessWidget {
  const _ScrimGradient({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _ReplayTopBar extends StatelessWidget {
  const _ReplayTopBar({
    required this.title,
    required this.pointsCount,
    required this.speedBadge,
  });

  final String title;
  final int pointsCount;
  final Widget speedBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onOverlay),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: colors.overlay.withValues(alpha: 0.26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onOverlay,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pointsCount data points',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onOverlay.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            speedBadge,
          ],
        ),
      ),
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.overlay.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SPD',
            style: TextStyle(
              color: colors.onOverlay.withValues(alpha: 0.54),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onOverlay,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayEmptyState extends StatelessWidget {
  const _ReplayEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final onOverlay = context.appColors.onOverlay;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight, size: 64, color: onOverlay.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: onOverlay.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaneMarker extends StatelessWidget {
  const _PlaneMarker({required this.headingDeg});
  final double headingDeg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: headingDeg * pi / 180,
        child: Icon(Icons.flight, color: cs.onPrimary, size: 28),
      ),
    );
  }
}

class _ReplayControlPanel extends StatelessWidget {
  const _ReplayControlPanel({
    required this.progress,
    required this.elapsed,
    required this.remaining,
    required this.altitude,
    required this.speed,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.playbackSpeeds,
    required this.onSeek,
    required this.onTogglePlayback,
    required this.onPlaybackSpeedChanged,
  });

  final double progress;
  final Duration elapsed;
  final Duration remaining;
  final String altitude;
  final String speed;
  final bool isPlaying;
  final double playbackSpeed;
  final List<double> playbackSpeeds;
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onPlaybackSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final divider = Container(
      width: 1,
      height: 32,
      color: colors.onOverlay.withValues(alpha: 0.1),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: colors.overlay.withValues(alpha: 0.55),
            border: Border.all(color: colors.onOverlay.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _TimeLabel(duration: elapsed),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        activeTrackColor: cs.primary,
                        inactiveTrackColor: colors.onOverlay.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: colors.onOverlay,
                        overlayColor: cs.primary.withValues(alpha: 0.15),
                      ),
                      child: Slider(value: progress, onChanged: onSeek),
                    ),
                  ),
                  _TimeLabel(duration: remaining),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatTile(label: 'ALT', value: altitude, icon: Icons.height),
                  divider,
                  _StatTile(label: 'SPEED', value: speed, icon: Icons.speed),
                  divider,
                  _StatTile(
                    label: 'TIME',
                    value: DurationFormatter.hms(elapsed),
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: onTogglePlayback,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause
                            : (progress >= 1.0
                                  ? Icons.replay
                                  : Icons.play_arrow),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (final s in playbackSpeeds)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _SpeedChip(
                        label: '${s.toInt()}x',
                        selected: playbackSpeed == s,
                        onTap: () => onPlaybackSpeedChanged(s),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.duration});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    final str = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '$m:${s.toString().padLeft(2, '0')}';
    return SizedBox(
      width: 48,
      child: Text(
        str,
        style: TextStyle(
          color: context.appColors.onOverlay.withValues(alpha: 0.7),
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onOverlay = context.appColors.onOverlay;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: onOverlay.withValues(alpha: 0.54)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onOverlay.withValues(alpha: 0.38),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: onOverlay,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onOverlay = context.appColors.onOverlay;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : onOverlay.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : onOverlay.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : onOverlay.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
