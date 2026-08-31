import 'package:flutter/material.dart';

/// A row displaying a fixed-width label and expanded value.
/// Used for detail views, GPS data, and metadata display.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final bool isMonospace;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100.0,
    this.labelStyle,
    this.valueStyle,
    this.isMonospace = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveLabelStyle = labelStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    final effectiveValueStyle = valueStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontFamily: isMonospace ? 'monospace' : null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: effectiveLabelStyle),
          ),
          Expanded(
            child: Text(value, style: effectiveValueStyle),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
