import 'package:flutter/material.dart';

import '../models/aircraft_class.dart';
import 'base_card.dart';
import 'info_chip.dart';

/// Shows the class an aircraft is flown under and opens the class picker
/// when tapped.
class AircraftClassCard extends StatelessWidget {
  const AircraftClassCard({
    super.key,
    required this.aircraftClass,
    required this.candidates,
    required this.onTap,
  });

  final AircraftClass? aircraftClass;

  /// Classes the aircraft's type allows (see [AircraftClass.candidatesFor]).
  final List<AircraftClass> candidates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = aircraftClass;

    final String title;
    final String subtitle;
    if (selected != null) {
      title = selected.label;
      subtitle = selected.description;
    } else if (candidates.length > 1) {
      title = 'Select class';
      subtitle =
          'Could be ${candidates.map((c) => c.label).join(' or ')}, '
          'depending on how it is flown.';
    } else {
      title = 'Select class';
      subtitle = 'Class or type rating this aircraft is flown under';
    }

    return BaseCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected != null
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected != null && candidates.contains(selected)) ...[
            const SizedBox(width: 8),
            const InfoChip(label: 'Matches type'),
          ],
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// What the user did in the class picker.
class AircraftClassChoice {
  const AircraftClassChoice(this.aircraftClass);

  /// Null when the user cleared the class.
  final AircraftClass? aircraftClass;
}

/// Lets the user pick the class of an aircraft. [candidates] are marked as
/// matching the aircraft type. Returns null when dismissed.
Future<AircraftClassChoice?> showAircraftClassPicker(
  BuildContext context, {
  required AircraftClass? selected,
  required List<AircraftClass> candidates,
}) {
  return showModalBottomSheet<AircraftClassChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;

        Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
          ),
        );

        Widget option(AircraftClass value) => ListTile(
          leading: Icon(
            value == selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: value == selected ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(value.label),
          subtitle: Text(value.description),
          trailing: candidates.contains(value)
              ? InfoChip(
                  label: 'Matches type',
                  backgroundColor: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                )
              : null,
          onTap: () => Navigator.pop(ctx, AircraftClassChoice(value)),
        );

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Aircraft Class', style: theme.textTheme.titleLarge),
            ),
            header('Class ratings'),
            for (final value in AircraftClass.classRatings) option(value),
            header('Type rating'),
            option(AircraftClass.type),
            header('Other licences'),
            for (final value in AircraftClass.nonPartFcl) option(value),
            if (selected != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('No class'),
                onTap: () =>
                    Navigator.pop(ctx, const AircraftClassChoice(null)),
              ),
            ],
          ],
        );
      },
    ),
  );
}
