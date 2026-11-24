import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show appBuildName;
import 'package:logging/logging.dart';

import 'database.dart';
import 'person_photo_store.dart';

/// Something went wrong while creating or restoring a backup. [message] is
/// meant to be shown to the user.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A serialized backup, ready to be written somewhere.
class BackupSnapshot {
  const BackupSnapshot({
    required this.bytes,
    required this.contentHash,
    required this.createdAt,
    required this.isEmpty,
  });

  /// The ZIP file.
  final Uint8List bytes;

  /// Hash of the backed-up data (not of the metadata), used to skip
  /// automatic backups when nothing changed.
  final String contentHash;
  final DateTime createdAt;

  /// True when the logbook has no flights, aircraft or people.
  final bool isEmpty;

  String get fileName => BackupService.fileNameFor(createdAt);
}

/// What a restore brought back.
class RestoreSummary {
  const RestoreSummary({
    required this.flights,
    required this.aircraft,
    required this.people,
    required this.photos,
    this.settings,
  });
  final int flights;
  final int aircraft;
  final int people;
  final int photos;

  /// The app settings in the backup, for the caller to apply; null for a
  /// backup made before settings were included.
  final Map<String, Object?>? settings;
}

/// Turns the whole app database into a portable file and back.
///
/// A backup is a ZIP holding:
/// - `manifest.json`: format, schema version, date, what is inside;
/// - `zenith.sqlite`: a consistent snapshot of the entire database (logbook,
///   airports, aircraft types...), taken with `VACUUM INTO`;
/// - `photos/<name>`: people's profile pictures, when included;
/// - `aircraft_photos/<name>`: aircraft photos picked by the user, when
///   photos are included. Aircraft photos found online are only links, and
///   travel inside the database.
/// - `signatures/<name>`: flight signatures and the pilot's own, always:
///   they are part of the logbook.
/// - `settings.json`: the app settings the caller passed in, when it did.
///   This service doesn't know what is in it: see `AppSettingsBackup`.
///
/// Restoring copies every table of the snapshot over the live database
/// inside one transaction, so the app keeps its open connection and a failed
/// restore changes nothing. A snapshot from an older schema still restores:
/// only the columns both sides have are copied.
class BackupService {
  BackupService(
    this._db,
    this._photos,
    this._aircraftPhotos,
    this._signatures,
    this._workDir,
  );

  final LogbookDatabase _db;
  final PersonPhotoStore _photos;
  final AircraftPhotoStore _aircraftPhotos;
  final SignatureStore _signatures;

  /// Scratch space for the database snapshot while it is packed/unpacked.
  final Future<Directory> Function() _workDir;
  static final _log = Logger('Backup');

  static const format = 'zenith-backup';
  static const formatVersion = 2;
  static const fileExtension = '.zip';
  static const filePrefix = 'zenith_backup_';
  static const mimeType = 'application/zip';

  static const _manifestEntry = 'manifest.json';
  static const _databaseEntry = 'zenith.sqlite';
  static const _photosPrefix = 'photos/';
  static const _aircraftPhotosPrefix = 'aircraft_photos/';
  static const _signaturesPrefix = 'signatures/';
  static const _settingsEntry = 'settings.json';

  static String fileNameFor(DateTime time, {String suffix = ''}) {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = time.toLocal();
    return '$filePrefix${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}$suffix$fileExtension';
  }

  /// Parses the time out of a name made by [fileNameFor], or null.
  static DateTime? timeFromFileName(String name) {
    final match = RegExp(
      r'^zenith_backup_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})',
    ).firstMatch(name);
    if (match == null) return null;
    final p = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return DateTime(p[0], p[1], p[2], p[3], p[4], p[5]);
  }

  static bool isBackupFileName(String name) =>
      name.startsWith(filePrefix) && name.endsWith(fileExtension);

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// [settings] (JSON-encodable) are stored alongside the data, and come
  /// back in [RestoreSummary.settings].
  Future<BackupSnapshot> create({
    required bool includePhotos,
    Map<String, Object>? settings,
  }) async {
    final createdAt = DateTime.now();
    final counts = await _counts();

    final snapshot = await _tempFile('snapshot');
    final Uint8List database;
    try {
      // A consistent, compacted copy of the live database, even while the
      // app keeps writing (e.g. a GPS track being recorded).
      await _db.customStatement('VACUUM INTO ?', [snapshot.path]);
      database = await snapshot.readAsBytes();
    } finally {
      if (snapshot.existsSync()) await snapshot.delete();
    }

    // Keyed by their path inside the ZIP.
    final photos = <String, Uint8List>{};
    if (includePhotos) {
      await _collectPhotos(
        photos,
        _photos,
        _photosPrefix,
        'SELECT photo AS name FROM people WHERE photo IS NOT NULL',
      );
      await _collectPhotos(
        photos,
        _aircraftPhotos,
        _aircraftPhotosPrefix,
        'SELECT photo_file AS name FROM aircrafts '
        'WHERE photo_file IS NOT NULL',
      );
    }
    await _collectPhotos(
      photos,
      _signatures,
      _signaturesPrefix,
      'SELECT signature_file AS name FROM flights '
      'WHERE signature_file IS NOT NULL '
      'UNION SELECT signature_file AS name FROM pilot_profile '
      'WHERE signature_file IS NOT NULL',
    );

    final manifest = jsonEncode({
      'format': format,
      'version': formatVersion,
      'schemaVersion': _db.schemaVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'appVersion': appBuildName,
      'includesPhotos': includePhotos,
      'includesSettings': settings != null,
      'counts': counts,
    });
    // Sorted, so the same settings always hash the same.
    final settingsJson = settings == null
        ? null
        : jsonEncode({
            for (final key in settings.keys.toList()..sort())
              key: settings[key],
          });

    // Hashing and compressing ~20 MB is noticeable; keep it off the UI.
    final (bytes, hash) = await Isolate.run(() {
      final parts = [sha256.convert(database).toString()];
      final archive = Archive()
        ..add(ArchiveFile.string(_manifestEntry, manifest))
        ..add(ArchiveFile.bytes(_databaseEntry, database));
      if (settingsJson != null) {
        parts.add('settings:${sha256.convert(utf8.encode(settingsJson))}');
        archive.add(ArchiveFile.string(_settingsEntry, settingsJson));
      }
      for (final MapEntry(:key, :value) in photos.entries) {
        parts.add('$key:${sha256.convert(value)}');
        archive.add(ArchiveFile.bytes(key, value));
      }
      final zip = ZipEncoder().encodeBytes(
        archive,
        level: DeflateLevel.defaultCompression,
      );
      return (zip, sha256.convert(utf8.encode(parts.join('\n'))).toString());
    });

    _log.info(
      'Backup created: ${database.length} byte database, '
      '${photos.length} photo(s), ${bytes.length} bytes zipped.',
    );
    return BackupSnapshot(
      bytes: bytes,
      contentHash: hash,
      createdAt: createdAt,
      isEmpty: counts.values.every((n) => n == 0),
    );
  }

  /// Reads into [photos] the files of [store] that the rows returned by
  /// [sql] name, each under [prefix].
  ///
  /// A method and not a closure inside [create]: a closure there would put
  /// `this`, and so the database, in the context that the isolate closure of
  /// [create] also captures, and a database can't be sent to an isolate.
  Future<void> _collectPhotos(
    Map<String, Uint8List> photos,
    PhotoStore store,
    String prefix,
    String sql,
  ) async {
    final dir = await store.directory;
    for (final row in await _db.customSelect(sql).get()) {
      final name = row.read<String>('name');
      final file = File('${dir.path}/$name');
      if (file.existsSync()) photos['$prefix$name'] = await file.readAsBytes();
    }
  }

  Future<Map<String, int>> _counts() async {
    final row = await _db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM flights) AS flights, '
          '(SELECT COUNT(*) FROM aircrafts) AS aircraft, '
          '(SELECT COUNT(*) FROM people) AS people',
        )
        .getSingle();
    return {
      'flights': row.read<int>('flights'),
      'aircraft': row.read<int>('aircraft'),
      'people': row.read<int>('people'),
    };
  }

  Future<File> _tempFile(String kind) async {
    final dir = await _workDir();
    if (!dir.existsSync()) await dir.create(recursive: true);
    final file = File(
      '${dir.path}/zenith_${kind}_${DateTime.now().microsecondsSinceEpoch}'
      '.sqlite',
    );
    if (file.existsSync()) await file.delete();
    return file;
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Reads the manifest of a backup without restoring it.
  static Future<Map<String, Object?>> readHeader(Uint8List bytes) async {
    final (manifest, _) = await _open(bytes, withContent: false);
    return manifest;
  }

  /// Replaces the entire database (and people's photos, when the backup has
  /// them) with the backup's content.
  Future<RestoreSummary> restore(Uint8List bytes) async {
    final (manifest, content) = await _open(bytes, withContent: true);
    final schema = manifest['schemaVersion'];
    if (schema is int && schema > _db.schemaVersion) {
      throw const BackupException(
        'This backup was made by a newer version of Zenith. '
        'Update the app to restore it.',
      );
    }

    final recording = await _db
        .customSelect(
          'SELECT 1 FROM flights '
          'WHERE is_recording = 1 AND arrival_time IS NULL LIMIT 1',
        )
        .get();
    if (recording.isNotEmpty) {
      throw const BackupException(
        'A flight is being recorded. Stop it before restoring a backup.',
      );
    }

    final (database, photos, aircraftPhotos, signatures, settings) = content!;
    final file = await _tempFile('restore');
    await file.writeAsBytes(database, flush: true);
    try {
      await _copyFrom(file);
    } finally {
      if (file.existsSync()) await file.delete();
    }

    final restoredPhotos =
        await _restorePhotos(_photos, photos, [('people', 'photo')]) +
        await _restorePhotos(_aircraftPhotos, aircraftPhotos, [
          ('aircrafts', 'photo_file'),
        ]);
    await _restorePhotos(_signatures, signatures, [
      ('flights', 'signature_file'),
      ('pilot_profile', 'signature_file'),
    ]);
    _db.markTablesUpdated(_db.allTables);

    final counts = await _counts();
    return RestoreSummary(
      flights: counts['flights']!,
      aircraft: counts['aircraft']!,
      people: counts['people']!,
      photos: restoredPhotos,
      settings: settings,
    );
  }

  /// Unzips and validates a backup. With [withContent], also returns the
  /// database snapshot, people's photos, aircraft photos, signatures and
  /// settings.
  static Future<
    (
      Map<String, Object?>,
      (
        Uint8List,
        Map<String, Uint8List>,
        Map<String, Uint8List>,
        Map<String, Uint8List>,
        Map<String, Object?>?,
      )?,
    )
  >
  _open(Uint8List bytes, {required bool withContent}) async {
    try {
      return await Isolate.run(() {
        final Archive archive;
        try {
          archive = ZipDecoder().decodeBytes(bytes);
        } catch (_) {
          throw const BackupException('This is not a Zenith backup file.');
        }
        final manifestFile = archive.findFile(_manifestEntry);
        final manifest = manifestFile == null
            ? null
            : jsonDecode(utf8.decode(manifestFile.content));
        if (manifest is! Map<String, dynamic> || manifest['format'] != format) {
          throw const BackupException('This is not a Zenith backup file.');
        }
        final version = manifest['version'];
        if (version is! int || version > formatVersion) {
          throw const BackupException(
            'This backup was made by a newer version of Zenith. '
            'Update the app to restore it.',
          );
        }
        final database = archive.findFile(_databaseEntry)?.content;
        if (database == null || database.isEmpty) {
          throw const BackupException('The backup has no database in it.');
        }
        if (!withContent) {
          return (manifest, null);
        }

        Map<String, Uint8List> under(String prefix) => {
          for (final f in archive.files)
            if (f.isFile && f.name.startsWith(prefix))
              f.name.substring(prefix.length): f.content,
        };
        final settingsFile = archive.findFile(_settingsEntry);
        Map<String, Object?>? settings;
        if (settingsFile != null) {
          try {
            final decoded = jsonDecode(utf8.decode(settingsFile.content));
            if (decoded is Map<String, dynamic>) settings = decoded;
          } catch (_) {
            // Damaged settings don't stop the logbook from being restored.
          }
        }
        return (
          manifest,
          (
            database,
            under(_photosPrefix),
            under(_aircraftPhotosPrefix),
            under(_signaturesPrefix),
            settings,
          ),
        );
      });
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('The backup file is damaged or unreadable ($e).');
    }
  }

  /// Copies every table of the snapshot at [file] over the live database.
  Future<void> _copyFrom(File file) async {
    await _db.customStatement('ATTACH DATABASE ? AS backup', [file.path]);
    try {
      final check = await _db
          .customSelect('PRAGMA backup.quick_check')
          .getSingle();
      if (check.data.values.first != 'ok') {
        throw const BackupException('The backup database is damaged.');
      }
      final backupTables = {
        for (final row
            in await _db
                .customSelect(
                  "SELECT name FROM backup.sqlite_master WHERE type = 'table'",
                )
                .get())
          row.read<String>('name'),
      };

      await _db.transaction(() async {
        for (final table in _db.allTables) {
          final name = table.actualTableName;
          // Tables added after the backup was made are left as they are.
          if (!backupTables.contains(name)) continue;
          final live = await _columnsOf('main', name);
          final saved = (await _columnsOf('backup', name)).toSet();
          final columns = [
            for (final c in live)
              if (saved.contains(c)) '"$c"',
          ].join(', ');
          await _db.customStatement('DELETE FROM main."$name"');
          await _db.customStatement(
            'INSERT INTO main."$name" ($columns) '
            'SELECT $columns FROM backup."$name"',
          );
        }
      });
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Could not restore the database ($e).');
    } finally {
      await _db.customStatement('DETACH DATABASE backup');
    }
  }

  Future<List<String>> _columnsOf(String schema, String table) async {
    final info = await _db
        .customSelect('PRAGMA $schema.table_info("$table")')
        .get();
    return [for (final r in info) r.read<String>('name')];
  }

  /// Writes the backup's photos into [store], then makes that folder match
  /// the restored rows of each table of [references], whose column holds
  /// the file name: missing pictures are cleared, unused files deleted.
  Future<int> _restorePhotos(
    PhotoStore store,
    Map<String, Uint8List> photos,
    List<(String table, String column)> references,
  ) async {
    final dir = await store.directory;
    var written = 0;
    for (final MapEntry(:key, :value) in photos.entries) {
      // Names come from the file; never let one escape the folder.
      if (key.isEmpty || key.contains('/') || key.contains(r'\')) continue;
      await File('${dir.path}/$key').writeAsBytes(value);
      written++;
    }

    final referenced = <String>{};
    for (final (table, column) in references) {
      final rows = await _db
          .customSelect(
            'SELECT id, $column AS name FROM $table WHERE $column IS NOT NULL',
          )
          .get();
      for (final row in rows) {
        final name = row.read<String>('name');
        if (File('${dir.path}/$name').existsSync()) {
          referenced.add(name);
        } else {
          await _db.customStatement(
            'UPDATE $table SET $column = NULL WHERE id = ?',
            [row.read<int>('id')],
          );
        }
      }
    }
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!referenced.contains(name)) await file.delete();
    }
    return written;
  }
}
