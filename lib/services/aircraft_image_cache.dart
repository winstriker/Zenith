import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the online aircraft photos that have been shown once, so they can
/// be shown again without a connection.
///
/// The pictures live in `<app cache>/aircraft_images/`: a place that is part
/// of no backup (neither the app's nor the system's), that the system may
/// empty when the device runs out of space, and that is safe to delete at
/// any time, since every picture can be downloaded again.
///
/// The folder never grows past [maxBytes]: when it would, the pictures that
/// were shown longest ago are deleted. With a [maxBytes] of 0 nothing is
/// kept.
class AircraftImageCache {
  AircraftImageCache(
    this._root, {
    this.client,
    this._maxBytes = defaultMaxBytes,
  });

  final Future<Directory> Function() _root;

  /// Used for the downloads when given, e.g. in tests.
  final http.Client? client;

  /// Most space the saved pictures may take. Lowering it deletes the
  /// pictures that no longer fit.
  int get maxBytes => _maxBytes;
  int _maxBytes;
  set maxBytes(int value) {
    if (value == _maxBytes) return;
    _maxBytes = value;
    unawaited(trim());
  }

  static const defaultMaxBytes = 100 * 1024 * 1024;

  /// The sizes offered in the settings. 0 keeps nothing.
  static const maxBytesChoices = [
    0,
    50 * 1024 * 1024,
    100 * 1024 * 1024,
    250 * 1024 * 1024,
    500 * 1024 * 1024,
    1024 * 1024 * 1024,
  ];
  static const _timeout = Duration(seconds: 30);
  static const _partial = '.part';

  /// Downloads in progress, so a picture asked for twice is fetched once.
  final _loading = <String, Future<Uint8List>>{};

  /// The last requested [trim]; trims run one after the other.
  Future<void> _trimmed = Future.value();

  Future<Directory> get directory async {
    final dir = Directory('${(await _root()).path}/aircraft_images');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String url) async {
    final name = sha256.convert(utf8.encode(url)).toString();
    return File('${(await directory).path}/$name');
  }

  /// The picture at [url]: the saved copy when there is one, otherwise
  /// downloaded and saved. Throws when it is neither saved nor reachable.
  Future<Uint8List> load(String url) {
    return _loading[url] ??= _load(url).whenComplete(() {
      // A block, not `=> _loading.remove(url)`: that would hand the removed
      // future back to whenComplete, which would then wait for itself.
      _loading.remove(url);
    });
  }

  Future<Uint8List> _load(String url) async {
    final file = await _fileFor(url);
    if (file.existsSync()) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          // Remember it was just used: the least recently used go first.
          unawaited(_touch(file));
          return bytes;
        }
      } on FileSystemException {
        // Unreadable: download it again.
      }
    }

    final bytes = await _download(url);
    if (maxBytes <= 0) return bytes;
    try {
      // Written aside and renamed, so a half-written picture is never read.
      final partial = File('${file.path}$_partial');
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(file.path);
      unawaited(trim());
    } on FileSystemException {
      // No space left, for instance. The picture is still shown this once.
    }
    return bytes;
  }

  Future<Uint8List> _download(String url) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw http.ClientException(
          'Could not download the picture (${response.statusCode})',
          Uri.parse(url),
        );
      }
      return response.bodyBytes;
    } finally {
      if (this.client == null) client.close();
    }
  }

  Future<void> _touch(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } on FileSystemException {
      // Deleted meanwhile.
    }
  }

  /// Forgets the saved copy of [url], e.g. because it can't be decoded.
  Future<void> evict(String url) async {
    final file = await _fileFor(url);
    if (file.existsSync()) await file.delete();
  }

  /// Space taken by the saved pictures, in bytes.
  Future<int> size() async {
    var total = 0;
    await for (final entity in (await directory).list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Deletes every saved picture.
  Future<void> clear() async {
    final dir = await directory;
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Deletes the pictures used longest ago until the folder fits in
  /// [maxBytes] again.
  Future<void> trim() => _trimmed = _trimmed.then((_) => _trim());

  Future<void> _trim() async {
    try {
      final files = <(File, DateTime, int)>[];
      var total = 0;
      await for (final entity in (await directory).list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        // Leftovers of interrupted downloads are only in the way.
        if (entity.path.endsWith(_partial) &&
            DateTime.now().difference(stat.modified) > _timeout * 2) {
          await entity.delete();
          continue;
        }
        files.add((entity, stat.modified, stat.size));
        total += stat.size;
      }
      if (total <= maxBytes) return;
      files.sort((a, b) => a.$2.compareTo(b.$2));
      for (final (file, _, size) in files) {
        if (total <= maxBytes) break;
        await file.delete();
        total -= size;
      }
    } catch (_) {
      // Files can vanish while being listed (the system may empty the
      // cache). The next trim finishes the job. Never let an error through:
      // trims are chained, so one would make every later trim fail too.
    }
  }
}

/// An online aircraft photo, read from [AircraftImageCache] when it was
/// shown before and saved there otherwise.
@immutable
class CachedAircraftImage extends ImageProvider<CachedAircraftImage> {
  const CachedAircraftImage(this.url, this.cache);
  final String url;
  final AircraftImageCache cache;

  @override
  Future<CachedAircraftImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedAircraftImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _codec(key, decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _codec(
    CachedAircraftImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final bytes = await cache.load(url);
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } catch (_) {
        // Not a picture: don't keep serving it.
        await cache.evict(url);
        rethrow;
      }
    } catch (_) {
      // Let the next attempt (back online, say) start afresh instead of
      // getting this failure again from Flutter's in-memory image cache.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CachedAircraftImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedAircraftImage("$url")';
}

final aircraftImageCacheProvider = Provider<AircraftImageCache>((ref) {
  final cache = AircraftImageCache(getApplicationCacheDirectory);
  ref.listen(
    aircraftImageCacheLimitProvider,
    (_, limit) => cache.maxBytes = limit,
    fireImmediately: true,
  );
  return cache;
});

/// Most space the saved aircraft photos may take, as chosen in the settings.
class AircraftImageCacheLimit extends Notifier<int> {
  static const _key = 'aircraft_image_cache_max_bytes';

  @override
  int build() {
    _load();
    return AircraftImageCache.defaultMaxBytes;
  }

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getInt(_key);
      if (saved != null && saved >= 0) state = saved;
    } catch (_) {
      // No preferences (tests, for instance): keep the default.
    }
  }

  Future<void> setMaxBytes(int maxBytes) async {
    state = maxBytes;
    await (await SharedPreferences.getInstance()).setInt(_key, maxBytes);
  }
}

final aircraftImageCacheLimitProvider =
    NotifierProvider<AircraftImageCacheLimit, int>(AircraftImageCacheLimit.new);

/// Space taken by the saved aircraft photos, in bytes. Invalidate to refresh.
final aircraftImageCacheSizeProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(aircraftImageCacheProvider).size();
});
