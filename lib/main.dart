import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/flight_service.dart';
import 'services/airport_service.dart';
import 'services/hive_adapters.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FlightPointAdapter());
  Hive.registerAdapter(FlightSessionAdapter());
  Hive.registerAdapter(AirportAdapter());
  await FlightService().initialize();
  await AirportService().initHive();
  runApp(
    const ProviderScope(
      child: LogbookApp(),
    ),
  );
}
