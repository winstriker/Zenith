import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'providers/backup_providers.dart';

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
  final container = ProviderContainer();

  final callbackHandler = container.read(callbackServiceProvider);
  await callbackHandler.initialize();

  runApp(
    UncontrolledProviderScope(container: container, child: const LogbookApp()),
  );
}
