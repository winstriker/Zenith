import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/flight_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlightService().initialize();
  runApp(
    const ProviderScope(
      child: LogbookApp(),
    ),
  );
}
