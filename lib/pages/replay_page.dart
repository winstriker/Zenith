import 'dart:math' show sin, cos, atan2;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../providers/unit_provider.dart';
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

  // Animation controller for smooth 60fps playback
  late final AnimationController _animationController;
  late final Animation<double> _progressAnimation;

  // Flight data (pre-computed)
  late final List<LatLng> _pathPoints;
  late final List<double> _cumulativeDistances;
  late final double _totalDistance;
  late final Duration _replayDuration;
  late final int _pointsCount;

  // Current state (updated by animation)
  LatLng? _currentPosition;
  double _currentAltitude = 0;
  double? _currentSpeed;
  double? _currentHeading;
  int _currentSegmentIndex = 0;

  // Playback state
  double _speed = 1.0;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initFlightData();
    _initAnimationController();
  }

  void _initFlightData() {
    final points = widget.flight.dataPoints;
    _pointsCount = points.length;
    _pathPoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    if (points.length >= 2) {
      const dist = Distance();
      _cumulativeDistances = [0.0];
      for (int i = 1; i < points.length; i++) {
        final d = dist(_pathPoints[i - 1], _pathPoints[i]);
        _cumulativeDistances.add(_cumulativeDistances.last + d);
      }
      _totalDistance = _cumulativeDistances.last;
    } else {
      _cumulativeDistances = [0.0];
      _totalDistance = 0;
    }

    _replayDuration = _calculateDuration();
    _currentPosition = _pathPoints.isNotEmpty ? _pathPoints.first : null;
    if (points.isNotEmpty) {
      _currentAltitude = points.first.altitude.toDouble();
      _currentSpeed = points.first.speed;
      _currentHeading = points.first.heading;
    }
  }

  void _initAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: _replayDuration,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  Duration _calculateDuration() {
    if (widget.flight.duration != null &&
        widget.flight.duration!.inMicroseconds > 0) {
      return widget.flight.duration!;
    }
    final points = widget.flight.dataPoints;
    if (points.length >= 2) {
      final d = points.last.timestamp.difference(points.first.timestamp);
      if (d.inMicroseconds > 0) return d;
    }
    return const Duration(seconds: 30);
  }

  void _onAnimationTick() {
    final progress = _progressAnimation.value * _speed;
    if (progress >= 1.0) {
      _animationController.stop();
      return;
    }
    _updateCurrentPoint(progress.clamp(0.0, 1.0));
  }

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
    if (progress <= 0) {
      _currentPosition = _pathPoints.first;
      _currentSegmentIndex = 0;
      return;
    }
    if (progress >= 1) {
      _currentPosition = _pathPoints.last;
      _currentSegmentIndex = _pathPoints.length - 1;
      return;
    }

    final target = progress * _totalDistance;

    // Binary search for segment index (O(log n) instead of O(n))
    int low = 1;
    int high = _cumulativeDistances.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (_cumulativeDistances[mid] < target) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    _currentSegmentIndex = high.clamp(0, _cumulativeDistances.length - 2);

    final segStart = _cumulativeDistances[_currentSegmentIndex];
    final segEnd = _cumulativeDistances[_currentSegmentIndex + 1];
    final t = segEnd > segStart
        ? ((target - segStart) / (segEnd - segStart))
        : 0.0;

    final p1 = _pathPoints[_currentSegmentIndex];
    final p2 = _pathPoints[_currentSegmentIndex + 1];

    _currentPosition = LatLng(
      p1.latitude + (p2.latitude - p1.latitude) * t,
      p1.longitude + (p2.longitude - p1.longitude) * t,
    );

    // Interpolate altitude, speed, heading from data points
    if (_currentSegmentIndex < widget.flight.dataPoints.length - 1) {
      final dp1 = widget.flight.dataPoints[_currentSegmentIndex];
      final dp2 = widget.flight.dataPoints[_currentSegmentIndex + 1];

      _currentAltitude = dp1.altitude + (dp2.altitude - dp1.altitude) * t;
      _currentSpeed = dp1.speed != null && dp2.speed != null
          ? dp1.speed! + (dp2.speed! - dp1.speed!) * t
          : (dp1.speed ?? dp2.speed);
      _currentHeading = _computeBearing(dp1, dp2);
    }
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
    if (_progressAnimation.value >= 1.0) {
      _animationController.reset();
    }
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      // Adjust duration based on speed
      _animationController.duration = Duration(
        microseconds: (_replayDuration.inMicroseconds / _speed).round(),
      );
      _animationController.forward(from: _progressAnimation.value);
    }
    setState(() {});
  }

  void _setSpeed(double speed) {
    final wasPlaying = _animationController.isAnimating;
    final currentProgress = _progressAnimation.value;

    setState(() {
      _speed = speed;
    });

    if (wasPlaying) {
      _animationController.duration = Duration(
        microseconds: (_replayDuration.inMicroseconds / _speed).round(),
      );
      _animationController.forward(from: currentProgress);
    }
  }

  void _onSliderChanged(double value) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.value = value;
    _updateCurrentPoint(value);
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
    if (_progressAnimation.value <= 0 || _currentPosition == null) return [];
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

  void _fitMapBounds() {
    if (!_mapReady || _pathPoints.isEmpty) return;
    final startPoint = _pathPoints.first;
    _mapController.move(startPoint, 13.0);
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
    final points = widget.flight.dataPoints;
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;

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
                animation: _progressAnimation,
                builder: (context, _) {
                  if (_pathPoints.length < 2 || _currentPosition == null) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    children: [
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _buildTrailPoints(),
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
                  pointsCount: _pointsCount,
                  speedBadge: AnimatedBuilder(
                    animation: _progressAnimation,
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
              animation: _progressAnimation,
              builder: (context, _) {
                final elapsed = _replayDuration * _progressAnimation.value;
                return _ReplayControlPanel(
                  progress: _progressAnimation.value,
                  elapsed: elapsed,
                  remaining: _replayDuration - elapsed,
                  altitude: _formatAltitude(_currentAltitude, isMetric),
                  speed: _formatSpeed(_currentSpeed, isMetric),
                  isPlaying: _animationController.isAnimating,
                  playbackSpeed: _speed,
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
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onPlaybackSpeedChanged;

  static const _speeds = [1.0, 2.0, 4.0];

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
                  const SizedBox(width: 16),
                  for (final s in _speeds)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
