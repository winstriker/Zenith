import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/services/database.dart';
import 'app.dart';

final databaseProvider = Provider<LogbookDatabase>((ref) {
  return LogbookDatabase();
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LogbookApp()));
}
