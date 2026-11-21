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
        tileUpdateTransformer: _currentCameraOnResize(
          MapController.of(context),
        ),
      ),
      null => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// flutter_map emits its first resize event a frame late, carrying the camera
/// from before any move made in `onMapReady` (e.g. fitting a route). The
/// TileLayer then loads and prunes tiles for a view no longer shown, leaving
/// the map grey until the next gesture. Use the camera as it is now instead.
TileUpdateTransformer _currentCameraOnResize(MapController controller) =>
    TileUpdateTransformer.fromHandlers(
      handleData: (event, sink) {
        final e = event.mapEvent;
        if (e is MapEventNonRotatedSizeChange) {
          sink.add(
            TileUpdateEvent(
              mapEvent: MapEventNonRotatedSizeChange(
                source: e.source,
                oldCamera: e.oldCamera,
                camera: controller.camera,
              ),
            ),
          );
        } else if (!event.wasTriggeredByTap()) {
          sink.add(event);
        }
      },
    );
