import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

enum MeasurementUnit { metric, knots }

class UnitNotifier extends Notifier<MeasurementUnit> {
  static const prefsKey = 'measurement_unit';

  @override
  MeasurementUnit build() {
    final index = ref.read(sharedPreferencesProvider).getInt(prefsKey);
    return index != null && index >= 0 && index < MeasurementUnit.values.length
        ? MeasurementUnit.values[index]
        : MeasurementUnit.metric;
  }

  Future<void> setUnit(MeasurementUnit unit) async {
    state = unit;
    await ref.read(sharedPreferencesProvider).setInt(prefsKey, unit.index);
  }
}

final unitProvider = NotifierProvider<UnitNotifier, MeasurementUnit>(
  UnitNotifier.new,
);
