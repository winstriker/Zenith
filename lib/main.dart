import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook/services/database.dart';
import 'services/flight_service.dart';
import 'services/hive_adapters.dart';
import 'app.dart';

final databaseProvider = Provider<LogbookDatabase>((ref) {
  final db = LogbookDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FlightPointAdapter());
  Hive.registerAdapter(FlightSessionAdapter());
  await FlightService().initialize();
  runApp(const ProviderScope(child: LogbookApp()));
}
