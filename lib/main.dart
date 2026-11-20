import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'providers/backup_providers.dart';
import 'providers/shared_preferences_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint(
        '[${record.level.name}] (${record.loggerName}) at ${record.time}: ${record.message}',
      );
    }
  });
  // Awaited behind the native splash screen (kept until the first frame):
  // the first frame needs the theme and whether to show the intro.
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Before the first frame, so a Material You theme doesn't flash in.
  await container.read(systemAccentProvider.notifier).load();

  // Not awaited: OAuth callbacks can be handled once the app is up.
  unawaited(container.read(callbackServiceProvider).initialize());

  runApp(
    UncontrolledProviderScope(container: container, child: const LogbookApp()),
  );
}
