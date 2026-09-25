import 'package:flutter/material.dart';

class DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  final TextAlign textAlign;

  const DateButton({
    super.key,
    required this.date,
    required this.onTap,
    this.textAlign = TextAlign.left,
  });

  String _formatDisplayDate(DateTime date) {
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
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}