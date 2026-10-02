import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// Used for block time in [FlightFormCard]
class TimePill extends StatelessWidget {
  const TimePill({super.key, this.start, this.end, required this.label});
  final tz.TZDateTime? start;
  final tz.TZDateTime? end;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    String blockTime = '0:00';
    if (start != null && end != null) {
      final diff = end!.difference(start!);
      if (!diff.isNegative) {
        final totalMinutes = diff.inMinutes;
        final h = totalMinutes ~/ 60;
        final m = totalMinutes % 60;
        blockTime = '$h:${m.toString().padLeft(2, '0')}';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            blockTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
