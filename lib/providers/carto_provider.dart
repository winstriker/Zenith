import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secret_store.dart';
import 'shared_preferences_provider.dart';

/// The CARTO API key, kept in the device's keystore.
class CartoApiKeyNotifier extends Notifier<String?> {
  static const _key = 'carto_api_key';

  /// Completes once the saved key has been read, so `null` can be told
  /// apart from "not loaded yet".
  late Future<void> loaded;

  @override
  String? build() {
    loaded = _loadKey();
    return null;
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
    final prefs = ref.read(sharedPreferencesProvider);
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

/// CARTO Voyager style; StyleReader keeps it in a disk cache.
const _styleUrl =
    'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

class CartoStyleNotifier extends AsyncNotifier<Style?> {
  @override
  Future<Style?> build() async {
    final key = ref.watch(cartoApiKeyProvider);
    if (key == null || key.isEmpty) return null;
    return StyleReader(
      uri: '$_styleUrl?key={key}',
      apiKey: key,
      logger: const Logger.console(),
    ).read();
  }
}

final cartoStyleProvider = AsyncNotifierProvider<CartoStyleNotifier, Style?>(
  CartoStyleNotifier.new,
);
