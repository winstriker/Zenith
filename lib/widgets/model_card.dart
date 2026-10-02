import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import 'aircraft_details_card.dart';
import 'base_card.dart';
import 'info_chip.dart';

class ModelCard extends StatelessWidget {
  const ModelCard({
    super.key,
    this.aircraft,
    this.onTap,
    this.useOuterPadding = true,
  });

  final IcaoAircraft? aircraft;
  final VoidCallback? onTap;
  final bool useOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final card = BaseCard(
      onTap: onTap,
      child: aircraft == null
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aircraft?.modelFullName ?? 'Select aircraft model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: aircraft != null
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 3),
                          Text(
                            aircraft!.manufacturer,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 3),
                          Text(
                            aircraft!.modelFullName,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InfoChip(
                            label: aircraft!.description.name.capitalize(),
                            backgroundColor: cs.secondaryContainer,
                            textColor: cs.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                          InfoChip(
                            label:
                                'Wake: ${aircraft!.wakeTurbolenceCategory.name}/${aircraft!.wakeTurbolenceGroup.name}',
                          ),
                          const SizedBox(width: 6),
                          InfoChip(
                            label:
                                '${aircraft!.engineCount}x ${aircraft!.engineType.name.capitalize()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InfoChip(
                  backgroundColor: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                  label: aircraft!.designator,
                ),
              ],
            ),
    );
    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }
}
