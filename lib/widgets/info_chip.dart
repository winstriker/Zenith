import 'package:flutter/material.dart';

/// A versatile chip/badge widget for displaying labeled information.
/// Unified replacement for _RouteChip, _StatChip, _buildChip, _buildInfoChip, _buildTypeChip.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
  });
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBg = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final effectiveTextColor = textColor ?? colorScheme.onSurfaceVariant;
    final effectiveRadius = borderRadius ?? 8.0;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(effectiveRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveTextColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                textStyle ??
                theme.textTheme.labelSmall?.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
