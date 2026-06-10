import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';

final databaseProviderForAircraft = databaseProvider;

class AircraftListNotifier extends Notifier<List<AircraftWithStats>> {
  @override
  List<AircraftWithStats> build() {
    _refresh();
    return [];
  }

  Future<void> _refresh() async {
    final db = ref.read(databaseProvider);
    state = await db.getAircraftsWithStats();
  }

  Future<void> refresh() => _refresh();
}

final aircraftListProvider = NotifierProvider<AircraftListNotifier, List<AircraftWithStats>>(AircraftListNotifier.new);
