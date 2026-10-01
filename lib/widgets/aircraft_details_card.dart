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
  final Aircraft aircraft;
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
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(aircraft.manufacturer),
              const Text(" - "),
              Text(aircraft.model),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InfoChip(
                label: aircraft.type,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                textColor: theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ),
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }
}
