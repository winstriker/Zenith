import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shared_preferences/shared_preferences.dart';

import 'carto_provider.dart';

final _log = logging.Logger('MapProvider');

/// The base map the user picked in settings.
enum MapSource {
  /// CARTO Voyager vector tiles; needs a CARTO API key.
  carto,

  /// Raster tiles from the OpenStreetMap public tile server.
  osm,
}

// ---------------------------------------------------------------------------
// Chosen source persistence
// ---------------------------------------------------------------------------
class MapSourceNotifier extends Notifier<MapSource> {
  static const prefsKey = 'map_source';

  /// Completes once the saved choice has been read.
  late Future<void> loaded;

  @override
  MapSource build() {
    loaded = _load();
    return MapSource.carto;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(prefsKey);
    state = MapSource.values.firstWhere(
      (s) => s.name == name,
      orElse: () => MapSource.carto,
    );
  }

  Future<void> setSource(MapSource source) async {
    state = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, source.name);
  }
}

final mapSourceProvider = NotifierProvider<MapSourceNotifier, MapSource>(
  MapSourceNotifier.new,
);

/// The source maps use given the saved choice and key: CARTO needs a key,
/// so without one the maps fall back to OpenStreetMap.
final effectiveMapSourceProvider = Provider<MapSource>((ref) {
  final source = ref.watch(mapSourceProvider);
  final key = ref.watch(cartoApiKeyProvider);
  return source == MapSource.carto && key != null
      ? MapSource.carto
      : MapSource.osm;
});

// ---------------------------------------------------------------------------
// Tiles to draw
// ---------------------------------------------------------------------------
sealed class MapTiles {
  const MapTiles();
}

class CartoMapTiles extends MapTiles {
  const CartoMapTiles(this.style);
  final Style style;
}

class OsmMapTiles extends MapTiles {
  const OsmMapTiles();
}

/// What the maps draw. Falls back to OpenStreetMap when there is no CARTO
/// key, when the user picked it, or when the CARTO style can't be loaded.
final mapTilesProvider = FutureProvider<MapTiles>((ref) async {
  final source = ref.watch(effectiveMapSourceProvider);
  // Until both settings are read, the source above may be a default: wait
  // for them. If one changes, this provider rebuilds with the real value.
  await Future.wait([
    ref.read(mapSourceProvider.notifier).loaded,
    ref.read(cartoApiKeyProvider.notifier).loaded,
  ]);
  if (!ref.mounted || source == MapSource.osm) return const OsmMapTiles();

  try {
    final style = await ref.watch(cartoStyleProvider.future);
    if (style != null) return CartoMapTiles(style);
  } catch (e) {
    _log.warning('CARTO style failed to load, using OpenStreetMap: $e');
  }
  return const OsmMapTiles();
});
