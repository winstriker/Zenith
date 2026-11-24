import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/sync_progress.dart';
import 'network.dart';
import 'registry_database.dart';

/// What a download of the registry brought: the file, and the version tag
/// the server gave it.
class RegistryDownload {
  const RegistryDownload(this.bytes, {this.etag});

  /// `aircraft.csv.gz` as served.
  final Uint8List bytes;
  final String? etag;
}

/// Fetches the registry file. Returns null when the server still has the
/// version tagged [etag] (HTTP 304). [onProgress] gets the bytes received
/// so far and the size of the file, when the server says it.
typedef RegistryDownloader =
    Future<RegistryDownload?> Function(
      String? etag,
      void Function(int received, int? total) onProgress,
    );

/// What is on the device of the registry.
@immutable
class RegistryStatus {
  const RegistryStatus({required this.aircraft, this.updatedAt});

  /// How many registrations are known. 0 until the first download.
  final int aircraft;

  /// When the list on the device was downloaded.
  final DateTime? updatedAt;

  bool get isDownloaded => aircraft > 0;
}

/// Keeps a copy of tar1090-db (https://github.com/wiedehopf/tar1090-db, the
/// aircraft list of the Mictronics database that readsb and tar1090 use) on
/// the device, to turn a registration into its ICAO address without asking
/// anyone.
///
/// Works like the airport data: downloaded at run time, never shipped with
/// the app, checked again once a day. The list is some 9 MB to download
/// and changes about once a week, so the daily check only asks the server
/// whether its copy changed (ETag) and downloads when it did.
class AircraftRegistryService {
  AircraftRegistryService(this.database, {RegistryDownloader? downloader})
    : _download = downloader ?? _httpDownload;

  final RegistryDatabase database;
  final RegistryDownloader _download;
  static final _log = Logger('Aircraft Registry');

  static final _url = Uri.parse(
    'https://raw.githubusercontent.com/wiedehopf/tar1090-db/csv/aircraft.csv.gz',
  );

  static const _etagKey = 'etag';
  static const _checkedAtKey = 'checked_at';
  static const _updatedAtKey = 'updated_at';
  static const _countKey = 'count';

  // Share of the overall progress bar given to the download.
  static const _downloadEnd = 0.5;
  static const _chunkSize = 20000;

  /// Live progress of the download.
  final progress = ValueNotifier<SyncProgress>(
    const SyncProgress(SyncPhase.idle),
  );

  bool get isBusy => progress.value.isRunning;

  void dispose() => progress.dispose();

  void _setProgress(
    SyncPhase phase, {
    double? fraction,
    String message = '',
    Object? error,
  }) {
    progress.value = SyncProgress(
      phase,
      fraction: fraction,
      message: message,
      error: error,
    );
  }

  Future<RegistryStatus> status() async {
    final count = int.tryParse(await database.meta(_countKey) ?? '') ?? 0;
    final updated = int.tryParse(await database.meta(_updatedAtKey) ?? '');
    return RegistryStatus(
      aircraft: count,
      updatedAt: updated == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updated),
    );
  }

  /// Brings the registry up to date. Does nothing when it was already
  /// checked today, unless [force]d.
  Future<void> loadData({bool force = false}) async {
    if (isBusy) return;
    // Mark as running synchronously so concurrent calls bail out above.
    _setProgress(
      SyncPhase.downloading,
      fraction: 0,
      message: 'Checking the aircraft database…',
    );

    try {
      final downloaded = (await status()).isDownloaded;
      if (!force && downloaded && await _checkedToday()) {
        _setProgress(
          SyncPhase.done,
          fraction: 1,
          message: 'Aircraft database is up to date',
        );
        return;
      }

      final stopwatch = Stopwatch()..start();
      final throttle = Stopwatch()..start();
      final download = await _download(
        // Without rows the file is needed whatever the server thinks we have.
        downloaded ? await database.meta(_etagKey) : null,
        (received, total) {
          if (throttle.elapsedMilliseconds < 100) return;
          throttle.reset();
          _setProgress(
            SyncPhase.downloading,
            fraction: total == null || total == 0
                ? null
                : (received / total).clamp(0, 1) * _downloadEnd,
            message: total == null
                ? 'Downloading aircraft database — ${_mb(received)} MB'
                : 'Downloading aircraft database — '
                      '${_mb(received)} / ${_mb(total)} MB',
          );
        },
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      if (download == null) {
        await database.setMeta(_checkedAtKey, '$now');
        _log.info('Aircraft registry unchanged on the server.');
        _setProgress(
          SyncPhase.done,
          fraction: 1,
          message: 'Aircraft database is up to date',
        );
        return;
      }

      _setProgress(
        SyncPhase.parsing,
        fraction: _downloadEnd,
        message: 'Processing aircraft database…',
      );
      // Unpacking and writing 600,000 rows would freeze the UI for seconds:
      // it all happens in a background isolate.
      final progressPort = ReceivePort();
      progressPort.listen((message) {
        _setProgress(
          SyncPhase.saving,
          fraction: _downloadEnd + (message as double) * (1 - _downloadEnd),
          message: 'Saving aircraft database…',
        );
      });
      final int count;
      try {
        count = await _syncInBackground(
          database,
          download.bytes,
          download.etag,
          now,
          progressPort.sendPort,
        );
      } finally {
        progressPort.close();
      }

      _log.info(
        'Aircraft registry: $count registrations in '
        '${stopwatch.elapsedMilliseconds} ms',
      );
      _setProgress(
        SyncPhase.done,
        fraction: 1,
        message: 'Aircraft database updated',
      );
    } catch (e, st) {
      _log.severe('Aircraft registry download failed', e, st);
      _setProgress(
        SyncPhase.error,
        message: 'Could not download the aircraft database',
        error: e,
      );
    }
  }

  /// Deletes the registry from the device.
  Future<void> clear() async {
    if (isBusy) return;
    await database.transaction(() async {
      await database.registeredAircrafts.deleteAll();
      await database.registryMeta.deleteAll();
    });
    // Give the space back to the system.
    await database.customStatement('VACUUM');
    _setProgress(SyncPhase.idle);
  }

  Future<bool> _checkedToday() async {
    final checked = int.tryParse(await database.meta(_checkedAtKey) ?? '');
    if (checked == null) return false;
    final now = DateTime.now();
    return !DateTime.fromMillisecondsSinceEpoch(
      checked,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  /// Static on purpose, like the airport sync: a closure made in an instance
  /// method may capture `this`, which can't be sent to another isolate.
  static Future<int> _syncInBackground(
    RegistryDatabase database,
    Uint8List bytes,
    String? etag,
    int now,
    SendPort progress,
  ) {
    return database.computeWithDatabase(
      computation: (db) => syncRegistry(
        db,
        bytes,
        etag: etag,
        now: now,
        onProgress: progress.send,
      ),
      connect: RegistryDatabase.new,
    );
  }

  /// Replaces the registry in [db] with the content of [file]
  /// (`aircraft.csv.gz`), in a single transaction, so a failure leaves the
  /// previous list untouched. Returns how many registrations it holds.
  static Future<int> syncRegistry(
    RegistryDatabase db,
    Uint8List file, {
    String? etag,
    int? now,
    void Function(double fraction)? onProgress,
  }) {
    final csv = _unpack(file);
    return db.transaction(() async {
      await db.registeredAircrafts.deleteAll();
      final chunk = <RegisteredAircraftsCompanion>[];
      Future<void> flush() async {
        if (chunk.isEmpty) return;
        // The file lists some aircraft twice.
        await db.batch(
          (b) => b.insertAll(
            db.registeredAircrafts,
            chunk,
            mode: InsertMode.insertOrIgnore,
          ),
        );
        chunk.clear();
      }

      for (final (registration, hex, offset) in parseRegistry(csv)) {
        chunk.add(
          RegisteredAircraftsCompanion.insert(
            registration: registration,
            hex: hex,
          ),
        );
        if (chunk.length >= _chunkSize) {
          await flush();
          onProgress?.call(offset / csv.length);
        }
      }
      await flush();

      final count = await db.registeredAircrafts.count().getSingle();
      if (count == 0) {
        // Never trade the list on the device for an empty or unreadable
        // file: throwing rolls the deletion above back.
        throw StateError('The aircraft database has no aircraft in it');
      }
      final time = '${now ?? DateTime.now().millisecondsSinceEpoch}';
      await db.setMeta(_countKey, '$count');
      await db.setMeta(_updatedAtKey, time);
      await db.setMeta(_checkedAtKey, time);
      if (etag != null) {
        await db.setMeta(_etagKey, etag);
      } else {
        await (db.delete(
          db.registryMeta,
        )..where((m) => m.key.equals(_etagKey))).go();
      }
      onProgress?.call(1);
      return count;
    });
  }

  /// The CSV inside [file]. A server may gzip the already gzipped file once
  /// more on the way.
  static Uint8List _unpack(Uint8List file) {
    var bytes = file;
    for (var i = 0; i < 2 && _isGzip(bytes); i++) {
      bytes = Uint8List.fromList(gzip.decode(bytes));
    }
    return bytes;
  }

  static bool _isGzip(Uint8List bytes) =>
      bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;

  /// Reads the tar1090-db CSV: one aircraft per line,
  /// `hex;registration;type;flags;description;year;owner;`. Yields the
  /// registration (as [RegistryDatabase.normalizeRegistration] spells it),
  /// the ICAO address in lower case, and how far into [csv] the line ends.
  /// Aircraft without a registration are skipped.
  ///
  /// Works on the bytes: the file is 34 MB of text, of which only the first
  /// two fields of each line are wanted.
  static Iterable<(String, String, int)> parseRegistry(Uint8List csv) sync* {
    const semicolon = 0x3B;
    const newline = 0x0A;
    final hexPattern = RegExp(r'^[0-9a-f]{6}$');
    var lineStart = 0;
    while (lineStart < csv.length) {
      var lineEnd = csv.indexOf(newline, lineStart);
      if (lineEnd < 0) lineEnd = csv.length;
      final hexEnd = csv.indexOf(semicolon, lineStart);
      if (hexEnd > lineStart && hexEnd < lineEnd) {
        var regEnd = csv.indexOf(semicolon, hexEnd + 1);
        if (regEnd < 0 || regEnd > lineEnd) regEnd = lineEnd;
        if (regEnd > hexEnd + 1) {
          final hex = String.fromCharCodes(
            csv,
            lineStart,
            hexEnd,
          ).trim().toLowerCase();
          final registration = RegistryDatabase.normalizeRegistration(
            String.fromCharCodes(csv, hexEnd + 1, regEnd),
          );
          if (registration.isNotEmpty && hexPattern.hasMatch(hex)) {
            yield (registration, hex, lineEnd);
          }
        }
      }
      lineStart = lineEnd + 1;
    }
  }

  static Future<RegistryDownload?> _httpDownload(
    String? etag,
    void Function(int received, int? total) onProgress,
  ) async {
    // autoUncompress off: the bytes received then match Content-Length, so
    // the percentage is right.
    final client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = networkTimeout;
    try {
      final request = await client.getUrl(_url);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (etag != null) {
        request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      final response = await request.close().withTimeout();
      if (response.statusCode == HttpStatus.notModified) {
        await response.drain<void>();
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'HTTP ${response.statusCode} while downloading the aircraft '
          'database',
          uri: _url,
        );
      }
      final total = response.contentLength > 0 ? response.contentLength : null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.withIdleTimeout()) {
        builder.add(chunk);
        onProgress(builder.length, total);
      }
      return RegistryDownload(
        builder.takeBytes(),
        etag: response.headers.value(HttpHeaders.etagHeader),
      );
    } finally {
      client.close(force: true);
    }
  }
}
