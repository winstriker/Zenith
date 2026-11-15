import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import 'aircraft_class_chips.dart';
import 'base_card.dart';
import 'info_chip.dart';

class AircraftDetailsCard extends StatelessWidget {
  const AircraftDetailsCard({
    super.key,
    required this.aircraft,
    this.useOuterPadding = true,
  });
  final AircraftWithStats aircraft;
  final bool useOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final card = BaseCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                aircraft.tailNumber,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(aircraft.manufacturer, style: theme.textTheme.titleSmall),
              const SizedBox(width: 4),
              Text(aircraft.modelFullName),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                label: aircraft.designator,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                textColor: theme.colorScheme.onTertiaryContainer,
              ),
              ...aircraftClassChips(
                context,
                aircraftClass: aircraft.aircraftClass,
                typeRating: aircraft.typeRating,
                description: aircraft.description,
                engineCount: aircraft.engineCount,
                engineType: aircraft.engineType,
              ),
            ],
          ),
          if (aircraft.totalFlightTime != null) ...[
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        const Text("Total Time", textAlign: TextAlign.center),
                        Text(
                          DurationFormatter.hm(
                            Duration(minutes: aircraft.totalFlightTime ?? 0),
                          ),
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  VerticalDivider(
                    width: 20,
                    thickness: 3,
                    radius: const BorderRadius.all(Radius.circular(2)),
                    indent: 5,
                    endIndent: 5,
                    color: cs.onSecondary,
                  ),
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        const Text("Landings", textAlign: TextAlign.center),
                        Text(
                          ((aircraft.dayLandings ?? 0) +
                                  (aircraft.nightLandings ?? 0))
                              .toString(),
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (aircraft.notes != null && aircraft.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              aircraft.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
