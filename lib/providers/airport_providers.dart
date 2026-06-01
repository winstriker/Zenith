import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airport_service.dart';

final airportServiceProvider = Provider<AirportService>((ref) => AirportService());

class AirportLoadNotifier extends ChangeNotifier {
  final AirportService _service;
  bool _initialized = false;

  AirportLoadNotifier(this._service);

  bool get isLoaded => _service.isLoaded;
  bool get isLoading => _service.isLoading;
  bool get isRefreshing => _service.isRefreshing;
  String? get error => _service.error;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _service.addListener(notifyListeners);
    _service.loadData();
  }

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> refresh() async {
    await _service.loadData();
  }
}

final airportLoadProvider = ChangeNotifierProvider<AirportLoadNotifier>((ref) {
  final service = ref.read(airportServiceProvider);
  final notifier = AirportLoadNotifier(service);
  notifier.initialize();
  return notifier;
});
