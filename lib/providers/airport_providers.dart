import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airport_service.dart';

final airportServiceProvider = Provider<AirportService>((ref) => AirportService());

class AirportLoadState {
  final bool isLoaded;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const AirportLoadState({
    required this.isLoaded,
    required this.isLoading,
    required this.isRefreshing,
    this.error,
  });
}

class AirportLoadNotifier extends Notifier<AirportLoadState> {
  late final AirportService _service;

  @override
  AirportLoadState build() {
    _service = ref.watch(airportServiceProvider);
    _service.addListener(_onServiceChange);
    ref.onDispose(() => _service.removeListener(_onServiceChange));
    if (!_service.isLoaded && !_service.isLoading) {
      _service.loadData();
    }
    return _buildState();
  }

  AirportLoadState _buildState() => AirportLoadState(
        isLoaded: _service.isLoaded,
        isLoading: _service.isLoading,
        isRefreshing: _service.isRefreshing,
        error: _service.error,
      );

  void _onServiceChange() {
    state = _buildState();
  }

  Future<void> refresh() async {
    await _service.loadData();
  }
}

final airportLoadProvider =
    NotifierProvider<AirportLoadNotifier, AirportLoadState>(AirportLoadNotifier.new);
