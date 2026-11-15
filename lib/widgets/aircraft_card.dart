import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import 'aircraft_details_card.dart';
import 'aircraft_photo_view.dart';
import 'base_card.dart';
import 'info_chip.dart';

class AircraftCard extends StatelessWidget {
  const AircraftCard({
    super.key,
    required this.aircraft,
    this.onTap,
    this.onLongPress,
    this.showStats = false,
    this.useOuterPadding = true,
  });
  final AircraftWithStats? aircraft;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showStats;
  final bool useOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final icon = Icon(
      Icons.airplanemode_active,
      size: 32,
      color: colorScheme.onSecondaryContainer,
    );

    final card = BaseCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Container(
            width: 100,
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            // The photo replaces the icon when the aircraft has one. Its
            // photographer and link are shown on the aircraft's page.
            child: aircraft?.photo == null
                ? icon
                : AircraftPhotoView(
                    photo: aircraft!.photo,
                    thumbnail: true,
                    placeholder: Center(child: icon),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: aircraft == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Aircraft Selected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to select',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aircraft!.tailNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${aircraft!.manufacturer} ${aircraft!.modelFullName}",
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 3),

                      if (showStats && aircraft is AircraftWithStats) ...[
                        Row(
                          children: [
                            InfoChip(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              label:
                                  '${(aircraft as AircraftWithStats).flightCount} flights',
                              icon: Icons.flight,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                            if ((aircraft as AircraftWithStats)
                                    .totalFlightTime !=
                                null) ...[
                              const SizedBox(width: 8),
                              InfoChip(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                label:
                                    '${((aircraft as AircraftWithStats).totalFlightTime! / 60).toStringAsFixed(1)}h',
                                icon: Icons.schedule,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                textColor: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            InfoChip(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              label:
                                  '${aircraft!.engineCount}x ${aircraft!.engineType.name.capitalize()}',
                            ),
                            const SizedBox(width: 4),
                            InfoChip(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              label:
                                  'Wake ${aircraft!.wakeTurbolenceCategory.name}/${aircraft!.wakeTurbolenceGroup.name}',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          if (aircraft != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aircraft!.designator,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }
}
