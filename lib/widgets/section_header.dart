import 'package:flutter/material.dart';

/// A standardized section header with optional uppercase styling.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.uppercase = false,
    this.style,
    this.trailing,
  });
  final String title;
  final bool uppercase;
  final TextStyle? style;
  final Widget? trailing;

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
      // The title stays centered on the full width, like headers without a
      // trailing widget.
      child: trailing != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                text,
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            )
          : text,
    );
  }
}
