import 'dart:async';
import 'dart:math' show sin, cos, atan2;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../services/database.dart';
import '../providers/unit_provider.dart';
import '../providers/carto_provider.dart';
import '../utils/duration_formatter.dart';

class ReplayPage extends ConsumerStatefulWidget {
  final FlightWithStats flight;

  const ReplayPage({super.key, required this.flight});

  @override
  ConsumerState<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends ConsumerState<ReplayPage> {
  final MapController _mapController = MapController();

  double _progress = 0.0;
  bool _isPlaying = false;
  double _speed = 1.0;
  Timer? _timer;

  List<LatLng> _pathPoints = [];
  List<double> _cumulativeDistances = [];
  double _totalDistance = 0;
  Duration _replayDuration = Duration.zero;

  LatLng? _currentPosition;
  double _currentAltitude = 0;
  double? _currentSpeed;
  double? _currentHeading;
  bool _mapReady = false;

  static const _tickPeriod = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();
    _initFlightData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initFlightData() {
    final points = widget.flight.dataPoints;
    _pathPoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    if (points.length >= 2) {
      final dist = Distance();
      _cumulativeDistances = [0.0];
      for (int i = 1; i < points.length; i++) {
        final d = dist(_pathPoints[i - 1], _pathPoints[i]);
        _cumulativeDistances.add(_cumulativeDistances.last + d);
      }
      _totalDistance = _cumulativeDistances.last;
    }

    _replayDuration = _calculateDuration();
    _currentPosition = _pathPoints.isNotEmpty ? _pathPoints.first : null;
    if (points.isNotEmpty) {
      _currentAltitude = points.first.altitude.toDouble();
      _currentSpeed = points.first.speed;
    }
  }

  Duration _calculateDuration() {
    if (widget.flight.duration != null &&
        widget.flight.duration!.inMicroseconds > 0) {
      return widget.flight.duration!;
    }
    final points = widget.flight.dataPoints;
    if (points.length >= 2) {
      final d =
          points.last.timestamp.difference(points.first.timestamp);
      if (d.inMicroseconds > 0) return d;
    }
    return const Duration(seconds: 30);
  }

  void _onMapReady() {
    _mapReady = true;
    _fitMapBounds();
  }

  void _fitMapBounds() {
    if (!_mapReady || _pathPoints.isEmpty) return;

    final startPoint = _pathPoints.first;

    _mapController.move(startPoint, 13.0);

    // Force a tiny movement to trigger a tile refresh and resolve the blurry tiles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          _mapController.camera.center,
          _mapController.camera.zoom + 0.000001,
        );
      }
    });
  }

  LatLng _getPositionAtProgress(double progress) {
    if (_pathPoints.isEmpty) return const LatLng(0, 0);
    if (_pathPoints.length == 1) return _pathPoints.first;
    if (progress <= 0) return _pathPoints.first;
    if (progress >= 1) return _pathPoints.last;

    final target = progress * _totalDistance;
    int i = 1;
    while (i < _cumulativeDistances.length &&
        _cumulativeDistances[i] < target) {
      i++;
    }
    if (i >= _cumulativeDistances.length) return _pathPoints.last;

    final segStart = _cumulativeDistances[i - 1];
    final segEnd = _cumulativeDistances[i];
    final t =
        segEnd > segStart ? ((target - segStart) / (segEnd - segStart)) : 0.0;
    final p1 = _pathPoints[i - 1];
    final p2 = _pathPoints[i];

    return LatLng(
      p1.latitude + (p2.latitude - p1.latitude) * t,
      p1.longitude + (p2.longitude - p1.longitude) * t,
    );
  }

  int _getSegmentIndex(double progress) {
    if (_pathPoints.length < 2 || progress >= 1) return _pathPoints.length - 1;
    if (progress <= 0) return 0;

    final target = progress * _totalDistance;
    int i = 1;
    while (i < _cumulativeDistances.length &&
        _cumulativeDistances[i] < target) {
      i++;
    }
    return i - 1;
  }

  void _updateCurrentPoint(double progress) {
    final points = widget.flight.dataPoints;
    if (points.isEmpty) return;

    _currentPosition = _getPositionAtProgress(progress);

    final segIndex = _getSegmentIndex(progress);
    if (segIndex < points.length - 1) {
      final segStart = _cumulativeDistances[segIndex];
      final segEnd = _cumulativeDistances[segIndex + 1];
      final t = segEnd > segStart
          ? ((progress * _totalDistance - segStart) / (segEnd - segStart))
          : 0.0;
      final p1 = points[segIndex];
      final p2 = points[segIndex + 1];

      _currentAltitude = p1.altitude + (p2.altitude - p1.altitude) * t;
      _currentSpeed = p1.speed != null && p2.speed != null
          ? p1.speed! + (p2.speed! - p1.speed!) * t
          : (p1.speed ?? p2.speed);
      _currentHeading = _computeBearing(p1, p2);
    } else if (points.isNotEmpty) {
      final p = points.last;
      _currentAltitude = p.altitude.toDouble();
      _currentSpeed = p.speed;
      _currentHeading = p.heading;
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
    if (_progress >= 1.0) {
      setState(() {
        _progress = 0.0;
        _updateCurrentPoint(0.0);
      });
    }
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    _isPlaying = true;
    _timer = Timer.periodic(_tickPeriod, (_) => _onTick());
  }

  void _pausePlayback() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
  }

  void _onTick() {
    if (_progress >= 1.0) {
      _pausePlayback();
      return;
    }
    final totalUs = _replayDuration.inMicroseconds.toDouble();
    if (totalUs <= 0) return;
    final step = (_tickPeriod.inMicroseconds / totalUs) * _speed;

    setState(() {
      _progress = (_progress + step).clamp(0.0, 1.0);
      _updateCurrentPoint(_progress);
      if (_progress >= 1.0) {
        _pausePlayback();
      }
    });
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
  }

  void _onSliderChanged(double value) {
    if (_isPlaying) _pausePlayback();
    setState(() {
      _progress = value;
      _updateCurrentPoint(value);
    });
  }

  String _formatAltitude(double meters, bool isMetric) {
    if (isMetric) {
      return '${meters.round()} m';
    }
    final feet = meters * 3.28084;
    return '${feet.round()} ft';
  }

  String _formatSpeed(double? speed, bool isMetric) {
    if (speed == null) return '--';
    if (isMetric) {
      return '${speed.round()} km/h';
    }
    final knots = speed * 0.539957;
    return '${knots.round()} kts';
  }

  List<LatLng> _buildTrailPoints() {
    if (_progress <= 0 || _currentPosition == null) return [];
    final idx = _getSegmentIndex(_progress);
    return [
      ..._pathPoints.sublist(0, idx + 1),
      _currentPosition!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final points = widget.flight.dataPoints;
    final unitMode = ref.watch(unitProvider);
    final isMetric = unitMode == MeasurementUnit.metric;
    final cartoStyle = ref.watch(cartoStyleProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          cartoStyle.when(
            data: (style) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: points.isNotEmpty
                    ? LatLng(points.first.latitude, points.first.longitude)
                    : const LatLng(51.5, -0.09),
                initialZoom: 10.0,
                onMapReady: _onMapReady,
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
                if (_pathPoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _pathPoints,
                        strokeWidth: 3,
                        color: cs.primary.withValues(alpha: 0.25),
                      ),
                      if (_progress > 0 && _currentPosition != null)
                        Polyline(
                          points: _buildTrailPoints(),
                          strokeWidth: 4,
                          color: cs.primary,
                        ),
                    ],
                  ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _buildPlaneMarker(cs),
                      ),
                    ],
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Failed to load map')),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            height: 140 + topPad,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: topPad + 4,
            left: 4,
            right: 4,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
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
                            widget.flight.flight.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_pathPoints.length} data points',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentSpeed != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SPD',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatSpeed(_currentSpeed, isMetric),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 260 + botPad,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: botPad + 16,
            left: 16,
            right: 16,
            child: _buildControlPanel(theme, cs, isMetric),
          ),

          if (_pathPoints.length < 2)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _pathPoints.isEmpty
                        ? 'No flight data available'
                        : 'Not enough points to replay',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaneMarker(ColorScheme cs) {
    final heading = _currentHeading ?? 0.0;
    final radians = heading * pi / 180;

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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: radians,
        child: const Icon(Icons.flight, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme, ColorScheme cs, bool isMetric) {
    final elapsed = _replayDuration * _progress;
    final remaining = _replayDuration - elapsed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
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
                            enabledThumbRadius: 7),
                        activeTrackColor: cs.primary,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                        overlayColor:
                            cs.primary.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: _progress,
                        onChanged: _onSliderChanged,
                        min: 0,
                        max: 1,
                      ),
                    ),
                  ),
                  _TimeLabel(duration: remaining),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatTile(
                    label: 'ALT',
                    value: _formatAltitude(_currentAltitude, isMetric),
                    icon: Icons.height,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _StatTile(
                    label: 'SPEED',
                    value: _formatSpeed(_currentSpeed, isMetric),
                    icon: Icons.speed,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
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
                      onPressed: _togglePlayback,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause
                            : (_progress >= 1.0
                                ? Icons.replay
                                : Icons.play_arrow),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  for (final s in [1.0, 2.0, 4.0])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _SpeedChip(
                        label: '${s.toInt()}x',
                        selected: _speed == s,
                        onTap: () => _setSpeed(s),
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
  final Duration duration;
  const _TimeLabel({required this.duration});

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
          color: Colors.white70,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
