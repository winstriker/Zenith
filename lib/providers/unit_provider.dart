import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MeasurementUnit { metric, knots }

class UnitNotifier extends StateNotifier<MeasurementUnit> {
  static const _key = 'measurement_unit';

  UnitNotifier() : super(MeasurementUnit.metric) {
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final unitIndex = prefs.getInt(_key);
    if (unitIndex != null && unitIndex >= 0 && unitIndex < MeasurementUnit.values.length) {
      state = MeasurementUnit.values[unitIndex];
    }
  }

  Future<void> setUnit(MeasurementUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, unit.index);
  }
}

final unitProvider = StateNotifierProvider<UnitNotifier, MeasurementUnit>((ref) {
  return UnitNotifier();
});
