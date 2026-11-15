import 'package:flutter/material.dart';

import '../services/database.dart';
import 'aircraft_details_card.dart';
import 'info_chip.dart';

/// The class or type rating of an aircraft as a pill, followed by its
/// engines when the class doesn't already tell them (e.g. a type rating or
/// TMG). Without a class, falls back to the aircraft description.
List<Widget> aircraftClassChips(
  BuildContext context, {
  required AircraftClass? aircraftClass,
  required String? typeRating,
  required AircraftDescription description,
  required int engineCount,
  required EngineType engineType,
  bool compact = false,
  EdgeInsetsGeometry? padding,
}) {
  final cs = Theme.of(context).colorScheme;
  final hasEngines = engineCount > 0 && engineType != EngineType.none;
  final showEngines =
      hasEngines && (aircraftClass == null || !aircraftClass.impliesEngine);

  String classLabel(AircraftClass c) {
    if (c != AircraftClass.type || typeRating == null) return c.label;
    return compact ? typeRating : 'Type rating: $typeRating';
  }

  return [
    if (aircraftClass != null)
      InfoChip(
        padding: padding,
        icon: Icons.workspace_premium_outlined,
        label: classLabel(aircraftClass),
        backgroundColor: cs.primaryContainer,
        textColor: cs.onPrimaryContainer,
      )
    else
      InfoChip(
        padding: padding,
        label: description.name.capitalize(),
        backgroundColor: cs.secondaryContainer,
        textColor: cs.onSecondaryContainer,
      ),
    if (showEngines)
      InfoChip(
        padding: padding,
        label: '${engineCount}x ${engineType.name.capitalize()}',
      ),
  ];
}
