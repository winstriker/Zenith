import 'package:flutter/material.dart';

/// Marks a value the pilot overrode for the logbook.
class OverriddenIcon extends StatelessWidget {
  const OverriddenIcon({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Overridden',
      child: Icon(
        Icons.edit_note,
        size: size,
        color: Theme.of(context).colorScheme.tertiary,
        semanticLabel: 'Overridden',
      ),
    );
  }
}
