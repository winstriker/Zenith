import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import 'base_card.dart';

/// Icon standing for a simulator wherever one is shown.
const simulatorIcon = Icons.desktop_windows_outlined;

/// A simulator in a list or a form, laid out like the aircraft card: what it
/// represents, then the device and where it is, with its kind and level as a
/// badge. Without [simulator], asks to pick one.
class SimulatorCard extends StatelessWidget {
  const SimulatorCard({
    super.key,
    required this.simulator,
    this.onTap,
    this.onLongPress,
    this.showStats = false,
    this.useOuterPadding = true,
  });

  final SimulatorWithStats? simulator;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Sessions and hours instead of the organisation.
  final bool showStats;
  final bool useOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sim = simulator;

    const minHeight = 80.0;
    const iconWidth = minHeight * 16 / 9;

    final card = BaseCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: iconWidth,
            child: ColoredBox(
              color: cs.secondaryContainer,
              child: Icon(
                simulatorIcon,
                size: 32,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(iconWidth + 16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sim == null
                              ? 'No Simulator Selected'
                              : sim.represents ?? sim.kind.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: sim == null ? null : FontWeight.w600,
                            color: sim == null ? cs.onSurfaceVariant : null,
                          ),
                        ),
                        Text(
                          sim == null ? 'Tap to select' : _subtitle(sim),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sim != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sim.deviceLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }

  String _subtitle(SimulatorWithStats sim) {
    if (showStats) {
      final count = sim.sessionCount;
      final sessions = '$count ${count == 1 ? 'session' : 'sessions'}';
      if (count == 0) return sessions;
      return '${(sim.totalMinutes / 60).toStringAsFixed(1)} hrs / $sessions';
    }
    final number = sim.simulator.qualificationNumber?.trim() ?? '';
    final organisation = sim.simulator.organisation?.trim() ?? '';
    final parts = [
      if (organisation.isNotEmpty) organisation,
      if (number.isNotEmpty) number,
    ];
    if (parts.isNotEmpty) return parts.join(' · ');
    return sim.type == null
        ? sim.kind.description
        : '${sim.type!.manufacturer} ${sim.type!.modelFullName}';
  }
}
