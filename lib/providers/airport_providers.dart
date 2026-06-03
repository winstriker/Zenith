import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airport_service.dart';

final airportServiceProvider = Provider<AirportsService>(
  (ref) => AirportsService(),
);

class AirportLoadNotifier extends Notifier<bool> {
  late final AirportsService _service;
  var isLoading = false;

  @override
  bool build() {
    _service = ref.watch(airportServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    isLoading = true;
    _service.loadData();
    return isLoading;
  }

  void _onServiceChange() {
    isLoading = false;
    state = false;
  }

  Future<void> refresh() async {
    isLoading = true;
    await _service.loadData(forceDownload: true);
  }
}

final airportLoadProvider = NotifierProvider<AirportLoadNotifier, bool>(
  AirportLoadNotifier.new,
);
