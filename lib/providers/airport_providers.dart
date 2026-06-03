import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airport_service.dart';

final airportServiceProvider = Provider<AirportsService>(
  (ref) => AirportsService(),
);

class AirportLoadNotifier extends Notifier<int> {
  late final AirportsService _service;

  @override
  int build() {
    _service = ref.watch(airportServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    _service.loadData();
    return 0;
  }

  void _onServiceChange() {
    state = state + 1;
  }

  Future<void> refresh() async {
    _onServiceChange();
    await _service.loadData(forceDownload: true);
  }
}

final airportLoadProvider = NotifierProvider<AirportLoadNotifier, int>(
  AirportLoadNotifier.new,
);
