import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/theme.dart';

/// Map moves made by the user, as opposed to the page's own.
const mapUserMoves = {
  MapEventSource.onDrag,
  MapEventSource.onMultiFinger,
  MapEventSource.flingAnimationController,
  MapEventSource.doubleTapZoomAnimationController,
  MapEventSource.doubleTapHold,
  MapEventSource.scrollWheel,
};

/// [child] faded out and untouchable while [visible] is false, e.g. while
/// the map under it is being moved.
class FadingOverlay extends StatelessWidget {
  const FadingOverlay({super.key, required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !visible,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: child,
    ),
  );
}

/// A vertical gradient that keeps the bars over a map readable.
class MapScrim extends StatelessWidget {
  const MapScrim({super.key, required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

/// Back button, title and subtitle drawn over a full-screen map.
class MapTopBar extends StatelessWidget {
  const MapTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onOverlay),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: colors.overlay.withValues(alpha: 0.26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onOverlay,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onOverlay.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Frosted panel for the controls drawn over a map.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.padding, required this.child});
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.overlay.withValues(alpha: 0.55),
            border: Border.all(color: colors.onOverlay.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A labelled value on a panel drawn over a map.
class MapStatTile extends StatelessWidget {
  const MapStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onOverlay = context.appColors.onOverlay;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: onOverlay.withValues(alpha: 0.54)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onOverlay.withValues(alpha: 0.38),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: onOverlay,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
