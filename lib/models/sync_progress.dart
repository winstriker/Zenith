import 'package:flutter/foundation.dart';

enum SyncPhase { idle, downloading, parsing, saving, done, error }

/// Snapshot of the progress of a reference data download: the OurAirports
/// airports, or the aircraft registry.
@immutable
class SyncProgress {
  const SyncProgress(
    this.phase, {
    this.fraction,
    this.message = '',
    this.error,
  });

  final SyncPhase phase;

  /// Overall completion between 0 and 1, or null when unknown.
  final double? fraction;
  final String message;
  final Object? error;

  bool get isRunning =>
      phase == SyncPhase.downloading ||
      phase == SyncPhase.parsing ||
      phase == SyncPhase.saving;

  /// Rounded percentage, or null when [fraction] is unknown.
  int? get percent => fraction == null ? null : (fraction! * 100).round();
}
