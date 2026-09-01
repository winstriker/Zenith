import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide Theme;

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

final cartoApiKeyProvider =
    NotifierProvider<CartoApiKeyNotifier, String?>(CartoApiKeyNotifier.new);

// ---------------------------------------------------------------------------
// CARTO Voyager style with disk cache via ephemeral local server
// ---------------------------------------------------------------------------
const _styleUrl =
    'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';
const _cacheFileName = 'carto_style_cache.json';
const _cacheMaxAge = Duration(hours: 24);

Future<File> _getCacheFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$_cacheFileName');
}

Future<bool> _isCacheFresh(File file) async {
  if (!await file.exists()) return false;
  try {
    final modified = await file.lastModified();
    return DateTime.now().difference(modified) < _cacheMaxAge;
  } catch (_) {
    return false;
  }
}

/// Starts an ephemeral HTTP server on localhost that serves [bytes] as JSON,
/// calls [reader] with the server URL, then closes the server.
Future<T> _serveCached<T>(
  List<int> bytes,
  Future<T> Function(String url) reader,
) async {
  HttpServer? server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    server.listen((request) {
      request.response
        ..headers.contentType = ContentType.json
        ..headers.contentLength = bytes.length
        ..add(bytes)
        ..close();
    });

    return await reader('http://127.0.0.1:$port/style.json');
  } finally {
    await server?.close(force: true);
  }
}

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
      final cacheFile = await _getCacheFile();
      Style? style;

      // Try disk cache first
      if (await _isCacheFresh(cacheFile)) {
        try {
          final bytes = await cacheFile.readAsBytes();
          style = await _serveCached(bytes, (url) async {
            return StyleReader(
              uri: '$url?key=$apiKey',
              apiKey: apiKey,
              logger: const Logger.console(),
            ).read();
          });
        } catch (_) {
          // Cache corrupted or server failed, fetch fresh
          style = null;
        }
      }

      // Network fetch
      style ??= await _fetchAndCacheStyle(apiKey, cacheFile);

      state = AsyncData(style);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<Style> _fetchAndCacheStyle(String apiKey, File cacheFile) async {
    final url = '$_styleUrl?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch CARTO style: ${response.statusCode}');
    }
    // Persist to disk
    await cacheFile.writeAsBytes(response.bodyBytes);
    // Parse from the network URL (StyleReader handles it natively)
    return StyleReader(
      uri: url,
      apiKey: apiKey,
      logger: const Logger.console(),
    ).read();
  }
}

final cartoStyleProvider =
    NotifierProvider<CartoStyleNotifier, AsyncValue<Style?>>(
  CartoStyleNotifier.new,
);
