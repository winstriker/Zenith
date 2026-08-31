import 'package:flutter/material.dart';

/// A standardized section header with optional uppercase styling.
class SectionHeader extends StatelessWidget {
  final String title;
  final bool uppercase;
  final TextStyle? style;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.uppercase = false,
    this.style,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveStyle =
        style ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    final displayTitle = uppercase ? title.toUpperCase() : title;

    final text = Text(
      displayTitle,
      style: effectiveStyle,
      textAlign: TextAlign.center,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: trailing != null
          ? Row(
              children: [
                Expanded(child: text),
                trailing!,
              ],
            )
          : text,
    );
  }
}
