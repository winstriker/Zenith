import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import 'shared_preferences_provider.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const prefsKey = 'theme_mode';

  @override
  ThemeMode build() {
    final themeIndex = ref.read(sharedPreferencesProvider).getInt(prefsKey);
    return themeIndex != null &&
            themeIndex >= 0 &&
            themeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, mode.index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class PaletteNotifier extends Notifier<AppPalette> {
  static const prefsKey = 'theme_palette';

  @override
  AppPalette build() {
    final name = ref.read(sharedPreferencesProvider).getString(prefsKey);
    return AppPalette.values.asNameMap()[name] ?? AppPalette.zenith;
  }

  Future<void> set(AppPalette palette) async {
    state = palette;
    await (await SharedPreferences.getInstance()).setString(
      prefsKey,
      palette.name,
    );
  }
}

final paletteProvider = NotifierProvider<PaletteNotifier, AppPalette>(
  PaletteNotifier.new,
);

/// Pure black background in the dark theme.
class OledNotifier extends Notifier<bool> {
  static const prefsKey = 'theme_oled';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setBool(prefsKey, value);
  }
}

final oledProvider = NotifierProvider<OledNotifier, bool>(OledNotifier.new);

/// Hides the status and navigation bars; a swipe from an edge shows them
/// for a moment.
class FullScreenNotifier extends Notifier<bool> {
  static const prefsKey = 'theme_full_screen';

  @override
  bool build() {
    final value =
        ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? false;
    _apply(value);
    return value;
  }

  Future<void> set(bool value) async {
    state = value;
    _apply(value);
    await (await SharedPreferences.getInstance()).setBool(prefsKey, value);
  }

  // Off is Flutter's default: both bars shown.
  static void _apply(bool value) => value
      ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
      : SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
}

final fullScreenProvider = NotifierProvider<FullScreenNotifier, bool>(
  FullScreenNotifier.new,
);

/// Whether the theme follows Android's wallpaper colors (see
/// [systemAccentProvider]) instead of the chosen palette.
class SystemColorsNotifier extends Notifier<bool> {
  static const prefsKey = 'theme_system_colors';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setBool(prefsKey, value);
  }
}

final systemColorsProvider = NotifierProvider<SystemColorsNotifier, bool>(
  SystemColorsNotifier.new,
);

/// Android's Material You accent, null where there is none (before
/// Android 12, other platforms). Call [load] at startup and on resume: the
/// wallpaper can change while the app is in the background.
class SystemAccentNotifier extends Notifier<Color?> {
  static const _channel = MethodChannel('zenith/system_colors');

  @override
  Color? build() => null;

  Future<void> load() async {
    try {
      final argb = await _channel.invokeMethod<int>('accent');
      state = argb == null ? null : Color(argb);
    } on MissingPluginException {
      state = null;
    } on PlatformException {
      state = null;
    }
  }
}

final systemAccentProvider = NotifierProvider<SystemAccentNotifier, Color?>(
  SystemAccentNotifier.new,
);
