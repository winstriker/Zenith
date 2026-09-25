import 'package:flutter/material.dart';
import 'package:logbook/widgets/section_header.dart';

class RemarksCard extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String>? onChanged;

  const RemarksCard({super.key, required this.initialValue, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'REMARKS & ENDORSEMENTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: initialValue,
              enabled: onChanged != null,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Add notes, endorsements, or remarks...',
              ),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
