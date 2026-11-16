import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/secret_store.dart';

// ---------------------------------------------------------------------------
// API Key persistence
// ---------------------------------------------------------------------------
/// The CARTO API key, kept in the device's keystore.
class CartoApiKeyNotifier extends Notifier<String?> {
  static const _key = 'carto_api_key';

  /// Completes once the saved key has been read, so `null` can be told
  /// apart from "not loaded yet".
  late Future<void> loaded;

  @override
  String? build() {
    loaded = _loadKey();
    return null; // while loading
  }

  Future<void> _loadKey() async {
    final store = ref.read(secretStoreProvider);
    String? key;
    try {
      key = await store.read(_key);
    } catch (_) {
      // A keystore that can't be read (restored onto another device, say)
      // is the same as nothing entered: the user enters it again.
    }
    // Older versions kept the key in the preferences: moved to the
    // keystore, and out of the preferences.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy != null) {
      if (key == null) {
        key = legacy;
        await store.write(_key, legacy);
      }
      await prefs.remove(_key);
    }
    if (ref.mounted) state = key;
  }

  Future<void> setKey(String key) async {
    final trimmed = key.trim();
    state = trimmed.isEmpty ? null : trimmed;
    await ref.read(secretStoreProvider).write(_key, trimmed);
  }

  Future<void> clearKey() => setKey('');
}

final cartoApiKeyProvider = NotifierProvider<CartoApiKeyNotifier, String?>(
  CartoApiKeyNotifier.new,
);

// ---------------------------------------------------------------------------
// CARTO Voyager style (disk-cache handled by StyleReader)
// ---------------------------------------------------------------------------
const _styleUrl =
    'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

class CartoStyleNotifier extends AsyncNotifier<Style?> {
  @override
  Future<Style?> build() async {
    final key = ref.watch(cartoApiKeyProvider);
    if (key == null || key.isEmpty) return null;
    return _loadStyle(key);
  }

  Future<Style?> _loadStyle(String apiKey) async {
    try {
      final style = await StyleReader(
        uri: '$_styleUrl?key={key}',
        apiKey: apiKey,
        logger: const Logger.console(),
      ).read();
      return style;
    } catch (e, st) {
      // Re-throw to let AsyncNotifier handle error state
      Error.throwWithStackTrace(e, st);
    }
  }
}

final cartoStyleProvider = AsyncNotifierProvider<CartoStyleNotifier, Style?>(
  CartoStyleNotifier.new,
);
