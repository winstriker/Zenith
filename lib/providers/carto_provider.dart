import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';

// ---------------------------------------------------------------------------
// API Key persistence
// ---------------------------------------------------------------------------
class CartoApiKeyNotifier extends Notifier<String?> {
  static const _key = 'carto_api_key';

  @override
  String? build() {
    _loadKey();
    return null; // while loading
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setKey(String key) async {
    final trimmed = key.trim();
    state = trimmed.isEmpty ? null : trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, trimmed);
    }
  }

  Future<void> clearKey() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final cartoApiKeyProvider = NotifierProvider<CartoApiKeyNotifier, String?>(
  CartoApiKeyNotifier.new,
);

// ---------------------------------------------------------------------------
// CARTO Voyager style (disk-cache handled by StyleReader)
// ---------------------------------------------------------------------------
const _styleUrl =
    'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

class CartoStyleNotifier extends Notifier<AsyncValue<Style?>> {
  @override
  AsyncValue<Style?> build() {
    final key = ref.watch(cartoApiKeyProvider);
    if (key == null || key.isEmpty) {
      return const AsyncData(null);
    }
    _loadStyle(key);
    return const AsyncLoading();
  }

  Future<void> _loadStyle(String apiKey) async {
    state = const AsyncLoading();
    try {
      final style = await StyleReader(
        uri: '$_styleUrl?key={key}',
        apiKey: apiKey,
        logger: const Logger.console(),
      ).read();

      state = AsyncData(style);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final cartoStyleProvider =
    NotifierProvider<CartoStyleNotifier, AsyncValue<Style?>>(
      CartoStyleNotifier.new,
    );
