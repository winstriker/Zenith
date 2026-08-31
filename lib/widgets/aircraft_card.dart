import 'package:flutter/material.dart';
import 'package:logbook/services/database.dart';
import 'gradient_card.dart';
import 'info_chip.dart';

class AircraftCard extends StatelessWidget {
  final AircraftWithStats aircraft;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AircraftCard({super.key, required this.aircraft, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = aircraft.aircraft;
    final hours = aircraft.totalFlightTime != null
        ? '${(aircraft.totalFlightTime!.inMinutes / 60).toStringAsFixed(1)}h'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GradientCard(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.airplanemode_active,
                color: theme.colorScheme.onSecondaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ac.tailNumber ?? ac.type,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (ac.model != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      ac.model!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InfoChip(
                        label: '${aircraft.flightCount} flights',
                        icon: Icons.flight,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.onSurfaceVariant,
                      ),
                      if (hours != null) ...[
                        const SizedBox(width: 8),
                        InfoChip(
                          label: hours,
                          icon: Icons.schedule,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ac.type,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
