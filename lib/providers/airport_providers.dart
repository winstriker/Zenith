import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airport_service.dart';

final airportServiceProvider = Provider<AirportService>((ref) => AirportService());

final airportDataLoadProvider = FutureProvider<void>((ref) async {
  final service = ref.read(airportServiceProvider);
  await service.loadData();
});
