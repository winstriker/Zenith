import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    hide Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/map_provider.dart';

/// OpenStreetMap public tile server. Per the tile usage policy: HTTPS only,
/// a distinct User-Agent, and no prefetching or offline downloads.
/// flutter_map's built-in cache honours the server's caching headers.
const _osmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Identifies the app to tile servers: sent as `flutter_map (<this>)`.
const _userAgentPackageName = 'it.winstriker.zenith';

/// The base map tiles: CARTO vector tiles, or OpenStreetMap raster tiles
/// when CARTO isn't available. Place it as the first child of a `FlutterMap`.
class BaseMapLayer extends ConsumerWidget {
  const BaseMapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(mapTilesProvider).value) {
      CartoMapTiles(:final style) => VectorTileLayer(
        tileProviders: style.providers,
        theme: style.theme,
        concurrency: 4,
        diskCacheTtl: const Duration(days: 30),
      ),
      OsmMapTiles() => TileLayer(
        urlTemplate: _osmUrlTemplate,
        userAgentPackageName: _userAgentPackageName,
      ),
      null => const Center(child: CircularProgressIndicator()),
    };
  }
}
