import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
