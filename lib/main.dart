import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/services/database.dart';
import 'app.dart';

final databaseProvider = Provider<LogbookDatabase>((ref) {
  final db = LogbookDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LogbookApp()));
}
