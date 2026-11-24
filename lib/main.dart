import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'providers/backup_providers.dart';
import 'providers/shared_preferences_provider.dart';
import 'providers/sync_providers.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (!kReleaseMode) {
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

  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(syncInBackground);
  }

  // Not awaited: OAuth callbacks can be handled once the app is up.
  unawaited(container.read(callbackServiceProvider).initialize());

  runApp(
    UncontrolledProviderScope(container: container, child: const LogbookApp()),
  );
}

/// Runs the sync the app schedules when it leaves the foreground, even if it
/// was closed since (Android). iOS only gives it ~30 s in the background, and
/// nothing once the app is swiped away.
@pragma('vm:entry-point')
void syncInBackground() {
  Workmanager().executeTask((task, input) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    try {
      await container.read(syncControllerProvider.notifier).syncAll();
    } finally {
      container.dispose();
    }
    return true;
  });
}
