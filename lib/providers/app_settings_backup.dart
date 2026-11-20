import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/aircraft_image_cache.dart';
import 'airport_providers.dart';
import 'backup_providers.dart';
import 'currency_settings_provider.dart';
import 'map_provider.dart';
import 'provider_toggles.dart';
import 'replay_speed_provider.dart';
import 'theme_provider.dart';
import 'unit_provider.dart';
import 'update_providers.dart';
import 'user_provider.dart';

/// How a preference is stored.
enum _Kind { bool, int, string, stringList }

/// The app settings that travel in backups, along with the logbook.
///
/// An allowlist on purpose: a preference only gets into a backup once it is
/// listed here, so nothing sensitive can end up in one by accident. Never
/// listed:
/// - secrets (API keys, cloud sign-ins): they aren't preferences at all,
///   but live in the device's keystore (`SecretStore`);
/// - what only makes sense on this device: backup status, when the
///   reference data was last downloaded, whether the intro was done.
class AppSettingsBackup {
  AppSettingsBackup._();

  static final _keys = {
    // Pilot.
    UserNicknameNotifier.prefsKey: _Kind.string,
    UserSignatureNameNotifier.prefsKey: _Kind.string,
    PicNameModeNotifier.prefsKey: _Kind.string,
    PicusColumnNotifier.prefsKey: _Kind.bool,
    // Preferences.
    ThemeNotifier.prefsKey: _Kind.int,
    UnitNotifier.prefsKey: _Kind.int,
    MapSourceNotifier.prefsKey: _Kind.string,
    CustomReplaySpeedNotifier.prefsKey: _Kind.int,
    LastReplaySpeed.prefsKey: _Kind.int,
    IcaoOnlyNotifier.prefsKey: _Kind.bool,
    excludedAirportTypesKey: _Kind.stringList,
    // Licence reminders.
    CurrencySettingsNotifier.enabledKey: _Kind.bool,
    CurrencySettingsNotifier.leadsKey: _Kind.stringList,
    CurrencySettingsNotifier.recencyKey: _Kind.bool,
    CurrencySettingsNotifier.timeKey: _Kind.int,
    // Online data.
    disabledTrackProvidersKey: _Kind.stringList,
    disabledHexSourcesKey: _Kind.stringList,
    disabledPhotoSourcesKey: _Kind.stringList,
    AircraftImageCacheLimit.prefsKey: _Kind.int,
    // Backups.
    for (final d in BackupDestination.values) ...{
      BackupSettingsNotifier.photosKey(d): _Kind.bool,
      BackupSettingsNotifier.frequencyKey(d): _Kind.string,
      BackupSettingsNotifier.keepKey(d): _Kind.int,
    },
    // Updates.
    AutoUpdateCheckNotifier.prefsKey: _Kind.bool,
  };

  /// Without these the app goes back to the intro: a backup can replace
  /// them, never clear them.
  static const _required = {
    UserNicknameNotifier.prefsKey,
    UserSignatureNameNotifier.prefsKey,
  };

  /// The keys that travel in backups.
  static Iterable<String> get keys => _keys.keys;

  /// The listed settings that are set, ready to be JSON-encoded.
  static Map<String, Object> read(SharedPreferences prefs) => {
    for (final key in _keys.keys)
      if (prefs.get(key) case final Object value) key: value,
  };

  /// Makes the listed settings match [settings], as read from a backup: a
  /// listed setting missing from it goes back to its default. Anything else
  /// in it (unknown keys, values of the wrong type) is ignored. The pilot's
  /// names are only ever replaced by non-empty ones.
  static Future<void> write(
    SharedPreferences prefs,
    Map<String, Object?> settings,
  ) async {
    for (final MapEntry(:key, value: kind) in _keys.entries) {
      final value = settings[key];
      if (_required.contains(key) &&
          (value is! String || value.trim().isEmpty)) {
        continue;
      }
      final ok = switch ((kind, value)) {
        (_Kind.bool, final bool v) => await prefs.setBool(key, v),
        (_Kind.int, final int v) => await prefs.setInt(key, v),
        (_Kind.string, final String v) => await prefs.setString(key, v),
        (_Kind.stringList, final List<Object?> v)
            when v.every((e) => e is String) =>
          await prefs.setStringList(key, v.cast<String>()),
        _ => false,
      };
      if (!ok) await prefs.remove(key);
    }
  }

  /// Applies [settings] from a backup, and has the app pick them up.
  static Future<void> restore(Ref ref, Map<String, Object?> settings) async {
    await write(await SharedPreferences.getInstance(), settings);
    // Each one reads its preferences when built.
    ref
      ..invalidate(userNicknameProvider)
      ..invalidate(userSignatureNameProvider)
      ..invalidate(picNameModeProvider)
      ..invalidate(picusColumnProvider)
      ..invalidate(themeProvider)
      ..invalidate(unitProvider)
      ..invalidate(mapSourceProvider)
      ..invalidate(customReplaySpeedProvider)
      ..invalidate(icaoOnlyProvider)
      ..invalidate(excludedAirportTypeNamesProvider)
      ..invalidate(currencySettingsProvider)
      ..invalidate(disabledTrackProvidersProvider)
      ..invalidate(disabledHexSourcesProvider)
      ..invalidate(disabledPhotoSourcesProvider)
      ..invalidate(aircraftImageCacheLimitProvider)
      ..invalidate(backupSettingsProvider)
      ..invalidate(autoUpdateCheckProvider);
  }
}
