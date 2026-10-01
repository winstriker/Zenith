import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import 'gradient_card.dart';
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
    final card = BaseCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                aircraft.tailNumber,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InfoChip(
                label: aircraft.designator,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                textColor: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Text(aircraft.manufacturer),
              const Text(" - "),
              Text(aircraft.modelFullName),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InfoChip(
                label:
                    '${aircraft.engineCount}x ${aircraft.engineType.name.capitalize()}',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              InfoChip(
                label: aircraft.description.name.capitalize(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
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
