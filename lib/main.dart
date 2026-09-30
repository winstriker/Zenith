import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'services/database.dart';

final databaseProvider = Provider<LogbookDatabase>((ref) {
  return LogbookDatabase();
});

void main() {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LogbookApp()));
}
