import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'services/database.dart';

final databaseProvider = Provider<LogbookDatabase>((ref) {
  return LogbookDatabase();
});

void main() {
  tz.initializeTimeZones();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print(
        '[${record.level.name}] (${record.loggerName}) at ${record.time}: ${record.message}',
      );
    }
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LogbookApp()));
}
