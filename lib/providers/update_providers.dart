import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_progress.dart';
import '../services/update_service.dart';
import 'shared_preferences_provider.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Whether to look for a new version when the app starts. On by default.
class AutoUpdateCheckNotifier extends Notifier<bool> {
  static const prefsKey = 'auto_update_check';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, value);
  }
}

final autoUpdateCheckProvider = NotifierProvider<AutoUpdateCheckNotifier, bool>(
  AutoUpdateCheckNotifier.new,
);

/// Where the update stands: [progress] for the About page, and the newer
/// [release] once one was found.
@immutable
class UpdateStatus {
  const UpdateStatus(this.progress, [this.release]);
  final SyncProgress progress;
  final AppRelease? release;
}

class UpdateNotifier extends Notifier<UpdateStatus> {
  /// The APK downloaded for [UpdateStatus.release], so a dismissed installer
  /// can be reopened without downloading it again.
  File? _apk;

  @override
  UpdateStatus build() => const UpdateStatus(SyncProgress(SyncPhase.idle));

  /// Looks for a newer release, returning it when there is one.
  Future<AppRelease?> check() async {
    if (state.progress.isRunning) return null;
    state = const UpdateStatus(
      SyncProgress(SyncPhase.downloading, message: 'Checking for updates…'),
    );
    try {
      final release = await ref.read(updateServiceProvider).latestNewer();
      _apk = null;
      state = UpdateStatus(
        SyncProgress(
          SyncPhase.done,
          message: release == null
              ? 'Zenith is up to date'
              : '${release.version} is available',
        ),
        release,
      );
      return release;
    } catch (e) {
      state = UpdateStatus(
        SyncProgress(
          SyncPhase.error,
          message: 'Could not check for updates: $e',
          error: e,
        ),
      );
      return null;
    }
  }

  /// Downloads the release found by [check] and opens the installer.
  Future<void> install() async {
    final release = state.release;
    if (release == null || state.progress.isRunning) return;
    final service = ref.read(updateServiceProvider);
    void report(double? fraction) {
      final progress = SyncProgress(
        SyncPhase.downloading,
        fraction: fraction,
        message: 'Downloading ${release.version}…',
      );
      // One rebuild per percent, not per network chunk.
      if (state.progress.phase != SyncPhase.downloading ||
          state.progress.percent != progress.percent) {
        state = UpdateStatus(progress, release);
      }
    }

    try {
      report(0);
      final apk = _apk ??= await service.download(release, report);
      state = UpdateStatus(
        SyncProgress(SyncPhase.done, message: '${release.version} is ready'),
        release,
      );
      await service.install(apk);
    } catch (e) {
      state = UpdateStatus(
        SyncProgress(
          SyncPhase.error,
          message: 'Could not install the update: $e',
          error: e,
        ),
        release,
      );
    }
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateStatus>(
  UpdateNotifier.new,
);
