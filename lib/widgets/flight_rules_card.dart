import 'package:flutter/material.dart';
import 'package:logbook/widgets/section_header.dart';

class FlightRulesCard extends StatelessWidget {
  final String flightRules;
  final ValueChanged<String>? onFlightRulesChanged;

  const FlightRulesCard({
    super.key,
    required this.flightRules,
    this.onFlightRulesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.rule, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLIGHT RULES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (onFlightRulesChanged == null) ...[
                    Text(
                      flightRules,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ] else ...[
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: flightRules,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'VFR', child: Text('VFR')),
                          DropdownMenuItem(value: 'IFR', child: Text('IFR')),
                          DropdownMenuItem(
                            value: 'Y',
                            child: Text('Y - IFR/VFR'),
                          ),
                          DropdownMenuItem(
                            value: 'Z',
                            child: Text('Z - VFR/IFR'),
                          ),
                          DropdownMenuItem(
                            value: 'Z2',
                            child: Text('Z2 - VFR/IFR'),
                          ),
                        ],
                        onChanged: (v) => onFlightRulesChanged!(v ?? 'VFR'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
