import 'package:flutter/material.dart';
import 'package:logbook/widgets/landing_counter.dart';

class LandingsCard extends StatelessWidget {
  final String approachType;
  final ValueChanged<String>? onApproachTypeChanged;
  final int nightLandings;
  final ValueChanged<int>? onNightLandingsChanged;
  final int dayLandings;
  final ValueChanged<int>? onDayLandingsChanged;

  const LandingsCard({
    super.key,
    required this.approachType,
    this.onApproachTypeChanged,
    required this.nightLandings,
    this.onNightLandingsChanged,
    required this.dayLandings,
    this.onDayLandingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  if (onApproachTypeChanged == null) ...[
                    Text(
                      approachType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ] else ...[
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: approachType,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'VISUAL',
                            child: Text('VISUAL'),
                          ),
                          DropdownMenuItem(value: 'ILS', child: Text('ILS')),
                          DropdownMenuItem(value: 'VOR', child: Text('VOR')),
                          DropdownMenuItem(value: 'NDB', child: Text('NDB')),
                          DropdownMenuItem(value: 'RNAV', child: Text('RNAV')),
                          DropdownMenuItem(value: 'GPS', child: Text('GPS')),
                          DropdownMenuItem(value: 'LOC', child: Text('LOC')),
                          DropdownMenuItem(
                            value: 'TACAN',
                            child: Text('TACAN'),
                          ),
                        ],
                        onChanged: (v) => onApproachTypeChanged!(v ?? 'VISUAL'),
                      ),
                    ),
                  ],
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
        ),
      ),
    );
  }
}
