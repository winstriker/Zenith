import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// OpenStreetMap / CARTO attribution, required by the tile licence.
/// Shown only in release builds; place it as a child of a `FlutterMap`.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
        ),
        child: Text(
          '© OpenStreetMap contributors,© CARTO',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
