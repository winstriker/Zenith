import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'date_button.dart';
import 'time_input.dart';
import 'time_pill.dart';

/// Date, start and end of a simulator session, in the phone's time zone,
/// with the total time of the session between them. An end earlier than the
/// start is on the next day.
class SessionTimesCard extends StatelessWidget {
  const SessionTimesCard({
    super.key,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.start,
    required this.end,
    required this.onDateTap,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime date;

  /// As typed, "HH:mm".
  final String startTime;
  final String endTime;

  /// The instants they stand for; [end] null until it is typed.
  final tz.TZDateTime start;
  final tz.TZDateTime? end;
  final VoidCallback onDateTap;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = theme.textTheme.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('START', style: label)),
                Expanded(
                  child: Text('END', textAlign: TextAlign.end, style: label),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: DateButton(date: date, onTap: onDateTap),
                ),
                Text(
                  'Local time · ${start.timeZone.abbreviation}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TimeInput(
                    value: startTime,
                    hint: 'HH:mm',
                    onChanged: onStartChanged,
                  ),
                ),
                const SizedBox(width: 8),
                TimePill(
                  label: 'Session',
                  start: startTime.isEmpty ? null : start,
                  end: end,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TimeInput(
                    value: endTime,
                    hint: 'HH:mm',
                    onChanged: onEndChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
