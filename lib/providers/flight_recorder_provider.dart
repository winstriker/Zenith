import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

import '../repositories/flight_repository.dart';

final _log = Logger('FlightRecorder');

/// A flight being recorded.
class Recording {
  const Recording({
    required this.flightId,
    required this.startedAt,
    required this.path,
    this.position,
    this.error,
  });

  final int flightId;
  final DateTime startedAt;

  /// Every position recorded so far, oldest first.
  final List<LatLng> path;

  /// The latest fix: null until the GPS gives one.
  final Position? position;

  /// Why positions aren't coming in, when they aren't.
  final String? error;
}

/// Why a recording couldn't start.
class RecordingException implements Exception {
  const RecordingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Records the GPS track of a flight, one point per fix, straight into the
/// database. On Android, geolocator's foreground service keeps it running
/// while the app is in the background. If the app is killed, [resume] picks
/// the recording up again on the next launch.
class FlightRecorder extends Notifier<Recording?> {
  StreamSubscription<Position>? _positions;

  @override
  Recording? build() {
    ref.onDispose(() => _positions?.cancel());
    return null;
  }

  FlightRepository get _repository => ref.read(flightRepositoryProvider);

  /// Starts recording a new flight. Throws [RecordingException] when the
  /// location can't be used.
  Future<void> start() async {
    if (state != null) return;
    await _ensureLocation();
    final id = await _repository.startSession();
    state = Recording(flightId: id, startedAt: DateTime.now(), path: const []);
    _listen();
  }

  /// Picks up the recording the app was killed during, if there was one.
  /// Returns whether there was.
  Future<bool> resume() async {
    if (state != null) return true;
    final flight = await _repository.activeRecording();
    if (flight == null) return false;
    final track = await _repository.getTrack(flight.id);
    state = Recording(
      flightId: flight.id,
      startedAt: flight.departureTime,
      path: [for (final p in track) LatLng(p.latitude, p.longitude)],
    );
    try {
      await _ensureLocation();
      _listen();
    } on RecordingException catch (e) {
      // Still shown as recording, so it can be stopped and kept.
      _setError(e.message);
    }
    return true;
  }

  /// Stops recording; the flight becomes a temporary flight. Returns
  /// whether it was kept: a recording without any position isn't.
  Future<bool> stop() async {
    final recording = state;
    if (recording == null) return false;
    await _positions?.cancel();
    _positions = null;
    state = null;
    return _repository.endSession(recording.flightId);
  }

  void _listen() {
    _positions?.cancel();
    _positions = Geolocator.getPositionStream(locationSettings: _settings)
        .listen(
          _onPosition,
          onError: (Object e) {
            _log.warning('Position stream failed', e);
            _setError('GPS unavailable: $e');
          },
        );
  }

  void _onPosition(Position p) {
    final recording = state;
    if (recording == null) return;
    state = Recording(
      flightId: recording.flightId,
      startedAt: recording.startedAt,
      path: [...recording.path, LatLng(p.latitude, p.longitude)],
      position: p,
    );
    _repository
        .addDataPoint(
          flightId: recording.flightId,
          latitude: p.latitude,
          longitude: p.longitude,
          altitude: p.altitude,
          timestamp: p.timestamp,
          // Tracks store km/h.
          speed: p.speed * 3.6,
          heading: p.heading,
        )
        .catchError((Object e) => _log.severe('Position not saved', e));
  }

  void _setError(String message) {
    final recording = state;
    if (recording == null) return;
    state = Recording(
      flightId: recording.flightId,
      startedAt: recording.startedAt,
      path: recording.path,
      position: recording.position,
      error: message,
    );
  }

  static Future<void> _ensureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const RecordingException('Turn on location to record a flight.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const RecordingException(
        'Zenith needs location access to record a flight.',
      );
    }
    // Shows the recording notification on Android 13+. Recording works
    // without it, so a refusal is fine.
    try {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      _log.warning('Notification permission request failed', e);
    }
  }

  /// "While in use" location is enough in the background: the foreground
  /// service is started while the app is in the foreground.
  static LocationSettings get _settings =>
      defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(
          intervalDuration: const Duration(seconds: 2),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Recording flight',
            notificationText: 'Zenith is recording your track',
            setOngoing: true,
            enableWakeLock: true,
          ),
        )
      : defaultTargetPlatform == TargetPlatform.iOS
      ? AppleSettings(
          // Auto-pause stays off (the default): it would cut a track
          // that looks stationary, e.g. while holding.
          activityType: ActivityType.airborne,
          // The blue pill tells the pilot recording is still running.
          showBackgroundLocationIndicator: true,
        )
      : const LocationSettings();
}

final flightRecorderProvider = NotifierProvider<FlightRecorder, Recording?>(
  FlightRecorder.new,
);
