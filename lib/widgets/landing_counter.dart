import 'package:flutter/material.dart';

class LandingCounter extends StatelessWidget {
  const LandingCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onChanged != null) ...[
              GestureDetector(
                onTap: () => onChanged!((value - 1).clamp(0, 99)),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onChanged != null) ...[
              GestureDetector(
                onTap: () => onChanged!(value + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 16, color: cs.onSurfaceVariant),
                ),
              ),
            ] else ...[
              const SizedBox(width: 20),
            ],
          ],
        ),
      ],
    );
  }
}
