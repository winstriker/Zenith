import 'package:flutter/material.dart';
import '../widgets/landing_counter.dart';
import '../widgets/picker_sheet.dart';

class LandingsCard extends StatelessWidget {
  const LandingsCard({
    super.key,
    required this.approachType,
    this.onApproachTypeChanged,
    required this.nightLandings,
    this.onNightLandingsChanged,
    required this.dayLandings,
    this.onDayLandingsChanged,
    this.mountainLandings,
    this.onMountainLandingsChanged,
  });
  final String approachType;
  final ValueChanged<String>? onApproachTypeChanged;
  final int nightLandings;
  final ValueChanged<int>? onNightLandingsChanged;
  final int dayLandings;
  final ValueChanged<int>? onDayLandingsChanged;

  /// Landings on surfaces designated to require a mountain rating, of the
  /// day and night ones (FCL.815(d)). Not shown when null.
  final int? mountainLandings;
  final ValueChanged<int>? onMountainLandingsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final mountain = mountainLandings;
    final landingsRow = Row(
      children: [
        Icon(Icons.flight_land, color: cs.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPROACH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              InlineSelect<String>(
                title: 'Approach',
                value: approachType,
                items: const [
                  'VISUAL',
                  'ILS',
                  'VOR',
                  'NDB',
                  'RNAV',
                  'GPS',
                  'LOC',
                  'TACAN',
                ],
                itemLabel: (v) => v,
                onChanged: onApproachTypeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        LandingCounter(
          label: 'NIGHT',
          value: nightLandings,
          onChanged: onNightLandingsChanged,
        ),
        const SizedBox(width: 16),
        LandingCounter(
          label: 'DAY',
          value: dayLandings,
          onChanged: onDayLandingsChanged,
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            landingsRow,
            // AMC1 FCL.050(i)(6): landings as pilot flying.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Landings as pilot flying.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (mountain != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.terrain_outlined,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOUNTAIN SURFACES',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Of the landings above, on surfaces designated to '
                          'require a mountain rating',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  LandingCounter(
                    label: 'MOUNTAIN',
                    value: mountain,
                    onChanged: onMountainLandingsChanged == null
                        ? null
                        : (v) => onMountainLandingsChanged!(
                            v.clamp(0, dayLandings + nightLandings),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
