import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/map_provider.dart';

final _osmCopyright = Uri.parse('https://www.openstreetmap.org/copyright');

/// OpenStreetMap / CARTO attribution, required by the tile licences.
/// Shown only in release builds; place it as a child of a `FlutterMap`.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topLeft,
      child: MapAttributionLabel(),
    );
  }
}

/// The attribution text on its own, for maps whose top-left corner is
/// covered by other UI. Tapping it opens the OpenStreetMap copyright page.
class MapAttributionLabel extends ConsumerWidget {
  const MapAttributionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kReleaseMode) return const SizedBox.shrink();
    final text = switch (ref.watch(mapTilesProvider).value) {
      CartoMapTiles() => '© OpenStreetMap contributors, © CARTO',
      OsmMapTiles() => '© OpenStreetMap contributors',
      null => null,
    };
    if (text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          launchUrl(_osmCopyright, mode: LaunchMode.externalApplication),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
