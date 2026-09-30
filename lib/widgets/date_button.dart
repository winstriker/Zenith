import 'package:flutter/material.dart';

class DateButton extends StatelessWidget {
  const DateButton({
    super.key,
    this.date,
    required this.onTap,
    this.textAlign = TextAlign.left,
  });
  final DateTime? date;
  final VoidCallback onTap;
  final TextAlign textAlign;

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _formatDisplayDate(date),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: date == null ? theme.colorScheme.onSurfaceVariant : null,
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}
