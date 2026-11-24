import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import 'backup_service.dart';
import 'cloud_backup_client.dart';
import 'database.dart';
import 'person_photo_store.dart';

/// What a sync did, for the caller to keep until the next one.
typedef SyncOutcome = ({
  /// State files of other devices taken in whole: not downloaded again.
  Set<String> applied,

  /// Hash of the state this device uploaded.
  String pushed,

  /// Rows changed on this device by what other devices sent.
  int received,
});

/// Keeps the logbook the same on every device that syncs through one cloud
/// folder, with no server: the cloud only stores files.
///
/// The database stays the source of truth and works offline. Triggers (see
/// [schema]) stamp every row the user changes in `sync_rows`, with the time
/// and a null device ("this one"); deletions leave the stamp behind. A sync:
/// 1. downloads the newest state file of every other device and applies the
///    rows whose stamp is newer than ours: last writer wins, per row;
/// 2. uploads this device's own state: every stamped row with its content.
///
/// Each device only writes its own files, so devices never overwrite each
/// other. Rows are named by their `sync_id` (integer ids differ between
/// devices), and references between rows travel as those names. Crew and
/// licence ratings travel inside their flight and licence; GPS tracks and
/// pictures are files of their own, uploaded once.
///
/// Housekeeping, after [horizon]: deletions stop travelling (every device
/// that still syncs has had them), and so do the states of devices that
/// stopped syncing. The folder never needs cleaning by hand.
///
/// Files in the folder:
/// - `state_<device>_<ms>.json.gz`: a device's state;
/// - `track_<flight>_<stamp>_<device>.json.gz`: a version of a track;
/// - `file_<name>`: a photo or signature, by its (unique) file name.
class SyncService {
  SyncService(
    this._db, {
    required this.deviceId,
    required PersonPhotoStore photos,
    required AircraftPhotoStore aircraftPhotos,
    required SignatureStore signatures,
  }) : _files = {
         ('people', 'photo'): photos,
         ('aircrafts', 'photo_file'): aircraftPhotos,
         ('flights', 'signature_file'): signatures,
         ('pilot_profile', 'signature_file'): signatures,
       };

  final LogbookDatabase _db;

  /// This device, in the names of its files and in the stamps it sends.
  final String deviceId;

  /// Where the file each column names is stored.
  final Map<(String, String), PhotoStore> _files;

  static final _log = Logger('Sync');

  static const format = 'zenith-sync';

  /// How long a deletion travels, and a silent device's state is kept.
  static const horizon = Duration(days: 90);

  /// What is synced, parents before the rows that point at them: the order
  /// changes are applied in (deletions go the other way).
  static const entities = [
    'icao_aircrafts', // the user's own types, named by designator/model/maker
    'airports', // the user's own airports
    'airport_logbook', // logbook overrides of OurAirports airports, by id
    'people',
    'aircrafts',
    'simulators',
    'flights',
    'tracks', // a flight's track, by the flight's sync_id
    'licences',
    'medical_certificates',
    'pilot_profile', // the single row, named "pilot"
  ];

  /// Columns that point at another table's row, and so travel as its name.
  static const _refs = {
    'aircrafts': {'icao_aircraft': 'icao_aircrafts'},
    'simulators': {'icao_aircraft': 'icao_aircrafts'},
    'flights': {
      'departure': 'airports',
      'arrival': 'airports',
      'aircraft_id': 'aircrafts',
      'simulator_id': 'simulators',
    },
  };

  /// What tells two rows apart when entered separately on two devices.
  static const _natural = {
    'people': ['name', 'surname'],
    'aircrafts': ['tail_number'],
    'simulators': ['kind', 'qualification_number', 'organisation'],
    // A pilot can't depart twice at the same time.
    'flights': ['departure_time'],
    'licences': ['kind', 'category'],
    'medical_certificates': ['medical_class', 'expiry_date'],
    'airports': ['ident'],
  };

  /// Separates designator, model and manufacturer in an ICAO type's name.
  static const _sep = '\u001f';
  static const _icaoKey =
      "designator || char(31) || model_full_name || char(31) || manufacturer";

  // ---------------------------------------------------------------------------
  // Schema
  // ---------------------------------------------------------------------------

  /// Milliseconds since the epoch, in SQL.
  static const _now =
      "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)";

  /// The time a change made now is stamped with: a hybrid logical clock.
  /// The device's clock corrected by its [_skew] from the cloud's, so every
  /// device stamps in the same time; and never older than a stamp received
  /// from another device, so an edit made after seeing another device's
  /// edit always wins over it.
  static const _clock = '(SELECT MAX($_now + skew, stamp + 1) FROM sync_clock)';

  /// Stamps, as changed on this device, the rows of [entity] that [keys] (a
  /// SELECT of a column `k`) names. The stamp is never older than the
  /// previous one, even if the clock went back; a row already stamped by
  /// the same statement isn't stamped again.
  static String _mark(String entity, String keys, {bool deleted = false}) {
    final d = deleted ? 1 : 0;
    return 'INSERT OR REPLACE INTO sync_rows (entity, key, stamp, device, '
        "deleted) SELECT '$entity', k, MAX(now, IFNULL((SELECT stamp FROM "
        "sync_rows WHERE entity = '$entity' AND key = k), 0) + 1), NULL, $d "
        'FROM ($keys), (SELECT $_clock AS now) '
        'WHERE k IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sync_muted) '
        "AND NOT EXISTS (SELECT 1 FROM sync_rows WHERE entity = '$entity' "
        'AND key = k AND device IS NULL AND deleted = $d AND stamp = now);';
  }

  static String _trigger(
    String name,
    String event,
    String table,
    List<String> body, {
    String? when,
  }) =>
      'CREATE TRIGGER sync_$name AFTER $event ON $table '
      '${when == null ? '' : 'WHEN $when '}BEGIN ${body.join(' ')} END';

  /// Tables and triggers of the sync, created with the database. Not drift
  /// tables, so backups don't carry them.
  static List<String> get schema {
    String own(String table, String row) =>
        'SELECT sync_id AS k FROM $table WHERE id = $row';
    String loggedFlight(String row) =>
        'SELECT sync_id AS k FROM flights WHERE id = $row '
        'AND is_recording = 0';
    const plain = [
      'people',
      'aircrafts',
      'simulators',
      'licences',
      'medical_certificates',
    ];
    const logbookChanged =
        'OLD.logbook_ident IS NOT NEW.logbook_ident '
        'OR OLD.logbook_annotate IS NOT NEW.logbook_annotate '
        'OR OLD.logbook_note IS NOT NEW.logbook_note';
    final oldIcao = _icaoKey.replaceAllMapped(
      RegExp('designator|model_full_name|manufacturer'),
      (m) => 'OLD.${m[0]}',
    );
    final newIcao = _icaoKey.replaceAllMapped(
      RegExp('designator|model_full_name|manufacturer'),
      (m) => 'NEW.${m[0]}',
    );

    return [
      // deleted: 1 a deletion, 2 one older than [horizon], kept only so a
      // device that missed it can't bring the row back.
      'CREATE TABLE sync_rows (entity TEXT NOT NULL, key TEXT NOT NULL, '
          'stamp INTEGER NOT NULL, device TEXT, deleted INTEGER NOT NULL, '
          'PRIMARY KEY (entity, key)) WITHOUT ROWID',
      // Holds a row while changes from other devices are written, which
      // the triggers must not stamp as this device's.
      'CREATE TABLE sync_muted (x INTEGER)',
      // The newest stamp received from another device, and how far the
      // cloud's clock is ahead of this device's (see [_clock]).
      'CREATE TABLE sync_clock (stamp INTEGER NOT NULL, skew INTEGER NOT NULL)',
      'INSERT INTO sync_clock VALUES (0, 0)',
      // Rows other devices have: never merged with a look-alike (see
      // [_adopt]).
      'CREATE TABLE sync_shared (entity TEXT NOT NULL, key TEXT NOT NULL, '
          'PRIMARY KEY (entity, key)) WITHOUT ROWID',
      for (final t in plain) ...[
        _trigger('${t}_ins', 'INSERT', t, [
          _mark(t, 'SELECT NEW.sync_id AS k'),
        ]),
        _trigger('${t}_upd', 'UPDATE', t, [
          _mark(t, 'SELECT NEW.sync_id AS k'),
        ]),
        _trigger('${t}_del', 'DELETE', t, [
          _mark(t, 'SELECT OLD.sync_id AS k', deleted: true),
        ]),
      ],
      // A flight being recorded isn't in the logbook yet.
      _trigger('flights_ins', 'INSERT', 'flights', [
        _mark('flights', 'SELECT NEW.sync_id AS k'),
      ], when: 'NEW.is_recording = 0'),
      _trigger('flights_upd', 'UPDATE', 'flights', [
        _mark('flights', 'SELECT NEW.sync_id AS k'),
      ], when: 'NEW.is_recording = 0'),
      // Its track was recorded while the flight wasn't synced.
      _trigger('flights_done', 'UPDATE OF is_recording', 'flights', [
        _mark('tracks', 'SELECT NEW.sync_id AS k'),
      ], when: 'OLD.is_recording = 1 AND NEW.is_recording = 0'),
      _trigger('flights_del', 'DELETE', 'flights', [
        _mark('flights', 'SELECT OLD.sync_id AS k', deleted: true),
        _mark('tracks', 'SELECT OLD.sync_id AS k', deleted: true),
      ]),
      for (final (event, row) in [
        ('INSERT', 'NEW'),
        ('UPDATE', 'NEW'),
        ('DELETE', 'OLD'),
      ]) ...[
        _trigger('crew_${event.toLowerCase()}', event, 'flight_crew', [
          _mark('flights', loggedFlight('$row.flight')),
        ]),
        _trigger('points_${event.toLowerCase()}', event, 'flight_data_points', [
          _mark('tracks', loggedFlight('$row.flight')),
        ]),
        _trigger('ratings_${event.toLowerCase()}', event, 'licence_ratings', [
          _mark('licences', own('licences', '$row.licence')),
        ]),
        _trigger('pilot_${event.toLowerCase()}', event, 'pilot_profile', [
          _mark('pilot_profile', "SELECT 'pilot' AS k", deleted: row == 'OLD'),
        ]),
      ],
      // OurAirports airports change with every airport data download: only
      // the user's own, and the overrides of the others, are synced.
      _trigger('airports_ins', 'INSERT', 'airports', [
        _mark('airports', 'SELECT NEW.sync_id AS k'),
      ], when: 'NEW.id < 0'),
      _trigger('airports_upd', 'UPDATE', 'airports', [
        _mark('airports', 'SELECT NEW.sync_id AS k'),
      ], when: 'NEW.id < 0'),
      _trigger('airports_del', 'DELETE', 'airports', [
        _mark('airports', 'SELECT OLD.sync_id AS k', deleted: true),
      ], when: 'OLD.id < 0'),
      _trigger(
        'airport_logbook_ins',
        'INSERT',
        'airports',
        [_mark('airport_logbook', 'SELECT CAST(NEW.id AS TEXT) AS k')],
        when:
            'NEW.id >= 0 AND (NEW.logbook_ident IS NOT NULL OR '
            'NEW.logbook_annotate IS NOT NULL OR NEW.logbook_note IS NOT NULL)',
      ),
      _trigger('airport_logbook_upd', 'UPDATE', 'airports', [
        _mark('airport_logbook', 'SELECT CAST(NEW.id AS TEXT) AS k'),
      ], when: 'NEW.id >= 0 AND ($logbookChanged)'),
      // ICAO types are named by what they are, the same on every device.
      // Renaming one of the user's own renames it for the aircraft too.
      _trigger('icao_ins', 'INSERT', 'icao_aircrafts', [
        _mark('icao_aircrafts', 'SELECT $newIcao AS k'),
      ], when: 'NEW.user_inserted = 1'),
      _trigger('icao_upd', 'UPDATE', 'icao_aircrafts', [
        _mark(
          'icao_aircrafts',
          'SELECT $oldIcao AS k WHERE $oldIcao IS NOT $newIcao',
          deleted: true,
        ),
        _mark('icao_aircrafts', 'SELECT $newIcao AS k'),
        _mark(
          'aircrafts',
          'SELECT sync_id AS k FROM aircrafts WHERE icao_aircraft = NEW.id '
              'AND $oldIcao IS NOT $newIcao',
        ),
        _mark(
          'simulators',
          'SELECT sync_id AS k FROM simulators WHERE icao_aircraft = NEW.id '
              'AND $oldIcao IS NOT $newIcao',
        ),
      ], when: 'OLD.user_inserted = 1 OR NEW.user_inserted = 1'),
      _trigger('icao_del', 'DELETE', 'icao_aircrafts', [
        _mark('icao_aircrafts', 'SELECT $oldIcao AS k', deleted: true),
      ], when: 'OLD.user_inserted = 1'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  static final _statePattern = RegExp(r'^state_([^_]+)_(\d+)\.json\.gz$');
  static final _trackPattern = RegExp(
    r'^track_([^_]+)_(\d+)_([^_]+)\.json\.gz$',
  );
  static const _filePrefix = 'file_';

  static String _trackName(String key, int stamp, String device) =>
      'track_${key}_${stamp}_$device.json.gz';

  /// Whether version ([s1], [d1]) is newer than ([s2], [d2]). Equal stamps
  /// are settled by device, the same way on every device.
  static bool _newer(int s1, String d1, int s2, String d2) =>
      s1 != s2 ? s1 > s2 : d1.compareTo(d2) > 0;

  /// A number that changes whenever this device stamps a change of its own
  /// (a re-stamped row only ever gets a bigger stamp); not on what other
  /// devices send, which is written muted.
  Future<int> localChanges() async =>
      (await _select(
            'SELECT IFNULL(SUM(stamp), 0) AS t FROM sync_rows '
            'WHERE device IS NULL',
          )).single['t']!
          as int;

  /// Brings the logbook and the cloud folder of [client] up to date with
  /// each other. [applied] and [pushed] come from the previous sync with the
  /// same folder; they only save downloads and uploads.
  Future<SyncOutcome> sync(
    CloudBackupClient client, {
    Set<String> applied = const {},
    String? pushed,
  }) async {
    final listing = {for (final f in await client.list()) f.name: f};
    await _skew(listing);
    final (:taken, :received, :complete) = await _pull(
      client,
      listing,
      applied,
    );
    await _db.customStatement(
      'UPDATE sync_rows SET deleted = 2 WHERE deleted = 1 AND stamp < ?',
      [DateTime.now().subtract(horizon).millisecondsSinceEpoch],
    );
    final hash = await _push(client, listing, pushed, clean: complete);
    return (applied: taken, pushed: hash, received: received);
  }

  /// Measures how far the cloud's clock is from this device's: the cloud
  /// dates this device's last state when it receives it, and its name says
  /// when the device sent it. Upload time only adds a few seconds.
  Future<void> _skew(Map<String, RemoteBackup> listing) async {
    int? sent;
    RemoteBackup? last;
    for (final f in listing.values) {
      final m = _statePattern.firstMatch(f.name);
      if (m == null || m[1] != deviceId) continue;
      final ms = int.parse(m[2]!);
      if (sent == null || ms > sent) (sent, last) = (ms, f);
    }
    if (sent == null) return;
    await _db.customStatement('UPDATE sync_clock SET skew = ?', [
      last!.createdAt.millisecondsSinceEpoch - sent,
    ]);
  }

  // ---------------------------------------------------------------------------
  // Pull
  // ---------------------------------------------------------------------------

  /// [_aliases] and [_replaced] live for one pull.
  Future<({Set<String> taken, int received, bool complete})> _pull(
    CloudBackupClient client,
    Map<String, RemoteBackup> listing,
    Set<String> applied,
  ) async {
    // The newest state of every other device.
    final latest = <String, (int, RemoteBackup)>{};
    for (final f in listing.values) {
      final m = _statePattern.firstMatch(f.name);
      if (m == null || m[1] == deviceId) continue;
      final ms = int.parse(m[2]!);
      if (ms > (latest[m[1]!]?.$1 ?? -1)) latest[m[1]!] = (ms, f);
    }

    // The newest version of each row across them.
    final incoming = <(String, String), _Row>{};
    final sources = <(String, String), String>{};
    final taken = <String>{};
    for (final (_, file) in latest.values) {
      if (applied.contains(file.name)) {
        taken.add(file.name);
        continue;
      }
      final List<_Row> rows;
      try {
        rows = _decodeState(await client.download(file.id, size: file.size));
      } on BackupException {
        rethrow;
      } catch (e) {
        // Taken all the same: it would fail again until replaced.
        _log.warning('Skipping unreadable ${file.name}: $e');
        taken.add(file.name);
        continue;
      }
      taken.add(file.name);
      for (final row in rows) {
        final id = (row.entity, row.key);
        final known = incoming[id];
        if (known == null ||
            _newer(row.stamp, row.device, known.stamp, known.device)) {
          incoming[id] = row;
          sources[id] = file.name;
        }
      }
    }
    if (incoming.isEmpty) return (taken: taken, received: 0, complete: true);

    _aliases.clear();
    await _db.transaction(() async {
      await _db.customStatement('INSERT INTO sync_muted VALUES (1)');
      await _db.customStatement('UPDATE sync_clock SET stamp = MAX(stamp, ?)', [
        incoming.values.map((r) => r.stamp).reduce(max),
      ]);
      for (final (entity, key) in incoming.keys) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO sync_shared VALUES (?, ?)',
          [entity, key],
        );
      }
      await _adopt(incoming);
      await _db.customStatement('DELETE FROM sync_muted');
    });

    // Only what is newer than this device's version.
    var local = await _versions();
    bool wins(_Row row) {
      final (s, d) = local[(row.entity, row.key)] ?? (0, '');
      return _newer(row.stamp, row.device, s, d);
    }

    final winners = incoming.values.where(wins).toList();

    // Tracks come as files of their own, fetched before writing anything.
    final failed = <(String, String)>{};
    final tracks = <String, Map<String, Object?>>{};
    for (final row in winners) {
      if (row.entity != 'tracks' || row.deleted) continue;
      if ((row.values?['points'] as int? ?? 0) == 0) continue;
      final file = listing[_trackName(row.key, row.stamp, row.device)];
      try {
        if (file == null) throw StateError('missing');
        tracks[row.key] = _decode(
          await client.download(file.id, size: file.size),
        );
      } catch (e) {
        _log.warning('Track of ${row.key} not available yet: $e');
        failed.add((row.entity, row.key));
      }
    }

    var received = 0;
    _replaced.clear();
    await _db.transaction(() async {
      await _db.customStatement('INSERT INTO sync_muted VALUES (1)');
      // Again: the user may have edited while the tracks downloaded.
      local = await _versions();
      final order = [
        for (final e in entities)
          for (final r in winners)
            if (r.entity == e && !r.deleted) r,
        for (final e in entities.reversed)
          for (final r in winners)
            if (r.entity == e && r.deleted) r,
      ];
      for (final row in order) {
        final id = (row.entity, row.key);
        if (failed.contains(id) || !wins(row)) continue;
        try {
          // A savepoint: a row is written whole or not at all.
          await _db.transaction(() async {
            await _db.customStatement(
              'INSERT OR REPLACE INTO sync_rows VALUES (?, ?, ?, ?, ?)',
              [
                row.entity,
                row.key,
                row.stamp,
                row.device == deviceId ? null : row.device,
                row.deleted ? 1 : 0,
              ],
            );
            await _apply(row, tracks[row.key]);
          });
          received++;
        } catch (e) {
          // Left for the next sync, e.g. an aircraft whose ICAO type isn't
          // downloaded here yet.
          _log.warning('Could not apply ${row.entity} ${row.key}: $e');
          failed.add(id);
        }
      }
      await _db.customStatement('DELETE FROM sync_muted');
    });
    _db.markTablesUpdated(_db.allTables);
    await _deleteUnused(_replaced);
    await _downloadFiles(client, listing);

    // A state with rows left over is read again next time.
    for (final id in failed) {
      taken.remove(sources[id]);
    }
    return (taken: taken, received: received, complete: failed.isEmpty);
  }

  /// Names from other devices standing for a row of this one: (entity,
  /// name) to sync_id.
  final _aliases = <(String, String), String>{};

  /// Pictures the rows changed by a pull named before.
  final _replaced = <(String, PhotoStore)>{};

  /// Gives one name to what was entered separately on this device and
  /// another before they first synced (the same flight, person...): the
  /// smaller of the two names wins on both, so they converge. Only rows no
  /// other device has yet are merged, so look-alikes that are really two
  /// (two pilots of the same name) stay two once synced.
  Future<void> _adopt(Map<(String, String), _Row> incoming) async {
    final known = {
      for (final r in await _select('SELECT entity, key FROM sync_rows'))
        (r['entity'] as String, r['key'] as String),
    };
    for (final row in [...incoming.values]) {
      final columns = _natural[row.entity];
      final values = row.values;
      if (columns == null ||
          values == null ||
          row.deleted ||
          known.contains((row.entity, row.key))) {
        continue;
      }
      final only = switch (row.entity) {
        'flights' => 'AND is_recording = 0 ',
        'airports' => 'AND id < 0 ',
        _ => '',
      };
      final match = await _select(
        'SELECT sync_id FROM ${row.entity} WHERE '
        '${columns.map((c) => '"$c" IS ? COLLATE NOCASE').join(' AND ')} '
        '${only}AND sync_id NOT IN '
        '(SELECT key FROM sync_shared WHERE entity = ?) ORDER BY sync_id LIMIT 1',
        [for (final c in columns) values[c], row.entity],
      );
      if (match.isEmpty) continue;
      final mine = match.first['sync_id'] as String;
      // One row stands for one: a second namesake stays a second person.
      if (_aliases.containsValue(mine)) continue;
      if (mine.compareTo(row.key) < 0) {
        // Ours keeps its name; the other device will take it.
        incoming.remove((row.entity, row.key));
        _aliases[(row.entity, row.key)] = mine;
        continue;
      }
      await _rename(row.entity, mine, row.key);
      if (row.entity == 'flights') await _rename('tracks', mine, row.key);
    }
  }

  /// Renames row [from] of [entity] to [to], and deletes [from] everywhere.
  Future<void> _rename(String entity, String from, String to) async {
    if (entity != 'tracks') {
      await _db.customStatement(
        'UPDATE $entity SET sync_id = ? WHERE sync_id = ?',
        [to, from],
      );
    }
    await _db.customStatement(
      'UPDATE sync_rows SET key = ? WHERE entity = ? AND key = ?',
      [to, entity, from],
    );
    await _db.customStatement(
      'INSERT OR REPLACE INTO sync_rows SELECT ?, ?, $_clock, NULL, 1',
      [entity, from],
    );
  }

  /// Deletes the pictures of [files] no row names anymore.
  Future<void> _deleteUnused(Set<(String, PhotoStore)> files) async {
    if (files.isEmpty) return;
    final used = (await _referencedFiles()).toSet();
    for (final file in files.difference(used)) {
      await file.$2.delete(file.$1);
    }
  }

  List<_Row> _decodeState(Uint8List bytes) {
    final json = _decode(bytes);
    if (json['format'] != format) throw const FormatException('not a state');
    final schema = json['schema'];
    if (schema is! int || schema > _db.schemaVersion) {
      throw const BackupException(
        'Another device syncs with a newer version of Zenith. Update the '
        'app to sync.',
      );
    }
    return [
      for (final r in (json['rows'] as List).cast<Map<String, dynamic>>())
        if (entities.contains(r['e']))
          _Row(
            entity: r['e'] as String,
            key: r['k'] as String,
            stamp: r['s'] as int,
            device: r['d'] as String,
            deleted: r['x'] == 1,
            values: r['v'] as Map<String, Object?>?,
            children: r['c'] as List<Object?>?,
          ),
    ];
  }

  /// This device's version of every row: (stamp, device).
  Future<Map<(String, String), (int, String)>> _versions() async => {
    for (final r in await _select('SELECT * FROM sync_rows'))
      (r['entity'] as String, r['key'] as String): (
        r['stamp'] as int,
        r['device'] as String? ?? deviceId,
      ),
  };

  /// Writes [row], from another device, into the logbook.
  Future<void> _apply(_Row row, Map<String, Object?>? track) async {
    final table = _tableOf(row.entity);
    final (where, args) = _match(row.entity, row.key);
    final found = await _select('SELECT * FROM $table WHERE $where', args);
    final id = found.isEmpty ? null : found.first['id'] as int;
    if (found.isNotEmpty) {
      for (final MapEntry(key: (t, column), value: store) in _files.entries) {
        if (t != table) continue;
        if (found.first[column] case final String name) {
          _replaced.add((name, store));
        }
      }
    }

    if (row.deleted) return _delete(row.entity, row.key, id);
    final values = row.values ?? const {};
    switch (row.entity) {
      case 'tracks':
        if (id == null) throw StateError('no such flight');
        await _db.customStatement(
          'DELETE FROM flight_data_points WHERE flight = ?',
          [id],
        );
        if (track == null) return;
        final columns = await _columns('flight_data_points');
        final names = (track['columns'] as List).cast<String>();
        final keep = [
          for (var i = 0; i < names.length; i++)
            if (columns.contains(names[i]) &&
                names[i] != 'id' &&
                names[i] != 'flight')
              i,
        ];
        final sql =
            'INSERT INTO flight_data_points (flight, '
            '${[for (final i in keep) '"${names[i]}"'].join(', ')}) '
            'VALUES (?${', ?' * keep.length})';
        for (final point in (track['rows'] as List).cast<List<Object?>>()) {
          await _db.customStatement(sql, [id, for (final i in keep) point[i]]);
        }
      case 'airport_logbook':
        if (id == null) throw StateError('airport not downloaded yet');
        await _upsert(table, id, await _columnsOf(table, values));
      case 'icao_aircrafts':
        // A type of the downloaded ICAO list with the same name wins.
        if (found.isNotEmpty && found.first['user_inserted'] == 0) return;
        await _upsert(table, id, {
          ...await _columnsOf(table, values),
          'user_inserted': 1,
        });
      default:
        final columns = await _columnsOf(table, values);
        for (final MapEntry(key: column, value: target)
            in (_refs[table] ?? const <String, String>{}).entries) {
          if (!values.containsKey(column)) continue;
          final name = values[column] as String?;
          final ref = name == null ? null : await _idOf(target, name);
          // Not here yet: wait for it, unless it was deleted here. What
          // can't be deleted while in use comes back (see [_delete]).
          // shortcut: not once the deletion stopped travelling ([horizon]);
          // drop the old deletion here if that shows up.
          final gone = target == 'aircrafts' ? 1 : 2;
          if (ref == null &&
              name != null &&
              !await _deleted(target, name, gone)) {
            throw StateError('$column $name not found');
          }
          columns[column] = ref;
        }
        if (id == null) {
          switch (row.entity) {
            case 'pilot_profile':
              columns['id'] = PilotProfile.rowId;
            case 'airports':
              columns['id'] =
                  (await _select(
                        'SELECT MIN(IFNULL(MIN(id), 0), 0) - 1 AS id '
                        'FROM airports',
                      )).first['id']
                      as int;
              columns['sync_id'] = row.key;
            default:
              columns['sync_id'] = row.key;
          }
        }
        final rowId = await _upsert(table, id, columns);
        final children = row.children ?? const [];
        if (row.entity == 'flights') {
          await _db.customStatement(
            'DELETE FROM flight_crew WHERE flight = ?',
            [rowId],
          );
          for (final member in children.cast<List<Object?>>()) {
            final person = await _idOf('people', member[0] as String);
            if (person == null) continue;
            await _db.customStatement(
              'INSERT OR REPLACE INTO flight_crew (flight, person, role) '
              'VALUES (?, ?, ?)',
              [rowId, person, member[1]],
            );
          }
        } else if (row.entity == 'licences') {
          await _db.customStatement(
            'DELETE FROM licence_ratings WHERE licence = ?',
            [rowId],
          );
          for (final rating in children.cast<Map<String, Object?>>()) {
            await _upsert('licence_ratings', null, {
              ...await _columnsOf('licence_ratings', rating),
              'licence': rowId,
            });
          }
        }
    }
  }

  /// Deletes row [id] of [entity] the way the app would, with what hangs
  /// off it. Rows still in use here are kept, and stamped as changed here so
  /// they come back on the device that deleted them.
  Future<void> _delete(String entity, String key, int? id) async {
    if (id == null) return;
    Future<bool> used(String sql) async =>
        (await _select(sql, [id, id])).isNotEmpty;
    Future<void> keep() => _db.customStatement(
      'UPDATE sync_rows SET stamp = $_clock, device = NULL, deleted = 0 '
      'WHERE entity = ? AND key = ?',
      [entity, key],
    );
    switch (entity) {
      case 'tracks':
        await _db.customStatement(
          'DELETE FROM flight_data_points WHERE flight = ?',
          [id],
        );
        return;
      case 'simulators'
          when await used(
            'SELECT 1 FROM flights WHERE simulator_id = ? OR simulator_id = ?',
          ):
        return keep();
      case 'airport_logbook' || 'pilot_profile':
        return;
      case 'airports'
          when await used(
            'SELECT 1 FROM flights WHERE departure = ? OR arrival = ?',
          ):
        return keep();
      case 'icao_aircrafts'
          when await used(
            'SELECT 1 FROM aircrafts WHERE icao_aircraft = ? UNION '
            'SELECT 1 FROM simulators WHERE icao_aircraft = ?',
          ):
        return keep();
      case 'flights':
        for (final t in ['flight_data_points', 'flight_crew']) {
          await _db.customStatement('DELETE FROM $t WHERE flight = ?', [id]);
        }
      case 'people':
        await _db.customStatement('DELETE FROM flight_crew WHERE person = ?', [
          id,
        ]);
      case 'aircrafts':
        await _db.customStatement(
          'UPDATE flights SET aircraft_id = NULL WHERE aircraft_id = ?',
          [id],
        );
      case 'licences':
        await _db.customStatement(
          'DELETE FROM licence_ratings WHERE licence = ?',
          [id],
        );
    }
    await _db.customStatement('DELETE FROM ${_tableOf(entity)} WHERE id = ?', [
      id,
    ]);
  }

  /// Downloads the pictures the logbook names that this device lacks.
  Future<void> _downloadFiles(
    CloudBackupClient client,
    Map<String, RemoteBackup> listing,
  ) async {
    for (final (name, store) in await _referencedFiles()) {
      final file = File('${(await store.directory).path}/$name');
      final remote = listing['$_filePrefix$name'];
      if (file.existsSync() || remote == null) continue;
      try {
        await file.writeAsBytes(
          await client.download(remote.id, size: remote.size),
        );
      } catch (e) {
        _log.warning('Could not download $name: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Push
  // ---------------------------------------------------------------------------

  /// With [clean], this device has every other device's latest state:
  /// pictures it doesn't name are named by no one.
  Future<String> _push(
    CloudBackupClient client,
    Map<String, RemoteBackup> listing,
    String? pushed, {
    required bool clean,
  }) async {
    final rows = await _db.transaction(_state);
    final tracks = {
      for (final r in rows)
        if (r['e'] == 'tracks')
          r['k'] as String: (r['s'] as int, r['d'] as String, r['x'] == 1),
    };

    // Files first: a state never names a file that isn't there.
    for (final r in rows) {
      final v = r['v'] as Map<String, Object?>?;
      if (r['e'] != 'tracks' || v == null || v['points'] == 0) continue;
      final name = _trackName(
        r['k'] as String,
        r['s'] as int,
        r['d'] as String,
      );
      if (listing.containsKey(name)) continue;
      final track = await _trackOf(r['k'] as String);
      if (track != null) await client.upload(name, _encode(track));
    }
    for (final (name, store) in await _referencedFiles()) {
      if (listing.containsKey('$_filePrefix$name')) continue;
      final file = File('${(await store.directory).path}/$name');
      if (file.existsSync()) {
        await client.upload('$_filePrefix$name', await file.readAsBytes());
      }
    }

    final state = utf8.encode(
      jsonEncode({
        'format': format,
        'schema': _db.schemaVersion,
        'device': deviceId,
        'rows': rows,
      }),
    );
    final hash = sha256.convert(state).toString();
    final mine = [
      for (final f in listing.values)
        if (_statePattern.firstMatch(f.name)?[1] == deviceId) f,
    ];
    if (hash != pushed || mine.isEmpty) {
      // Named with the device's own time: see [_skew].
      await client.upload(
        'state_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.json.gz',
        Uint8List.fromList(gzip.encode(state)),
      );
      for (final old in mine) {
        await client.delete(old.id);
      }
    }

    // Devices silent for so long they stopped syncing. One that comes back
    // uploads its state again, as on its first sync.
    final stale = DateTime.now().subtract(horizon);
    for (final f in listing.values) {
      final device = _statePattern.firstMatch(f.name)?[1];
      if (device != null && device != deviceId && f.createdAt.isBefore(stale)) {
        await client.delete(f.id);
      }
    }

    // Track versions this device knows to be outdated.
    for (final f in listing.values) {
      final m = _trackPattern.firstMatch(f.name);
      final ours = m == null ? null : tracks[m[1]!];
      if (ours == null) continue;
      final (stamp, device, deleted) = ours;
      if (deleted || _newer(stamp, device, int.parse(m![2]!), m[3]!)) {
        await client.delete(f.id);
      }
    }
    if (clean) {
      final used = {for (final (name, _) in await _referencedFiles()) name};
      // A day of grace: a device may have uploaded a picture and not yet
      // the state naming it.
      final before = DateTime.now().subtract(const Duration(days: 1));
      for (final f in listing.values) {
        if (f.name.startsWith(_filePrefix) &&
            !used.contains(f.name.substring(_filePrefix.length)) &&
            f.createdAt.isBefore(before)) {
          await client.delete(f.id);
        }
      }
    }
    return hash;
  }

  /// Every stamped row, with its content: this device's state.
  Future<List<Map<String, Object?>>> _state() async {
    final refs = <(String, int), String?>{};
    final rows = <Map<String, Object?>>[];
    for (final v in await _select('SELECT * FROM sync_rows')) {
      final entity = v['entity'] as String;
      final key = v['key'] as String;
      if (v['deleted'] == 2) continue;
      final deleted = v['deleted'] == 1;
      final row = <String, Object?>{
        'e': entity,
        'k': key,
        's': v['stamp'],
        'd': v['device'] ?? deviceId,
        if (deleted) 'x': 1,
      };
      if (!deleted) {
        if (!entities.contains(entity)) continue;
        final table = _tableOf(entity);
        final (where, args) = _match(entity, key);
        final found = await _select('SELECT * FROM $table WHERE $where', args);
        // Gone without a deletion: nothing to say about it.
        if (found.isEmpty) continue;
        final data = Map.of(found.first);
        final id = data.remove('id') as int;
        data.remove('sync_id');
        switch (entity) {
          case 'tracks':
            final n = await _select(
              'SELECT COUNT(*) AS n FROM flight_data_points WHERE flight = ?',
              [id],
            );
            row['v'] = {'points': n.first['n']};
          case 'airport_logbook':
            row['v'] = {
              for (final c in [
                'logbook_ident',
                'logbook_annotate',
                'logbook_note',
              ])
                c: data[c],
            };
          default:
            for (final MapEntry(key: column, value: target)
                in (_refs[table] ?? const <String, String>{}).entries) {
              final ref = data[column] as int?;
              data[column] = ref == null
                  ? null
                  : refs[(target, ref)] ??= await _nameOf(target, ref);
            }
            row['v'] = data;
            if (entity == 'flights') {
              row['c'] = [
                for (final c in await _select(
                  'SELECT p.sync_id AS person, c.role AS role '
                  'FROM flight_crew c JOIN people p ON p.id = c.person '
                  'WHERE c.flight = ?',
                  [id],
                ))
                  [c['person'], c['role']],
              ];
            } else if (entity == 'licences') {
              row['c'] = [
                for (final r in await _select(
                  'SELECT * FROM licence_ratings WHERE licence = ? '
                  'ORDER BY id',
                  [id],
                ))
                  Map.of(r)
                    ..remove('id')
                    ..remove('licence'),
              ];
            }
        }
      }
      rows.add(row);
    }
    return rows;
  }

  /// The track of the flight named [key], as uploaded.
  Future<Map<String, Object?>?> _trackOf(String key) async {
    final columns = [
      for (final c in await _columns('flight_data_points'))
        if (c != 'id' && c != 'flight') c,
    ];
    final points = await _select(
      'SELECT ${columns.map((c) => '"$c"').join(', ')} FROM flight_data_points '
      'WHERE flight = (SELECT id FROM flights WHERE sync_id = ?) '
      'ORDER BY timestamp',
      [key],
    );
    if (points.isEmpty) return null;
    return {
      'columns': columns,
      'rows': [
        for (final p in points) [for (final c in columns) p[c]],
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _tableOf(String entity) => switch (entity) {
    'airport_logbook' => 'airports',
    'tracks' => 'flights',
    _ => entity,
  };

  /// The WHERE clause finding the row [key] names in [entity]'s table.
  static (String, List<Object?>) _match(String entity, String key) =>
      switch (entity) {
        'icao_aircrafts' => (
          'designator = ? AND model_full_name = ? AND manufacturer = ? '
              'ORDER BY id LIMIT 1',
          key.split(_sep),
        ),
        'airport_logbook' => ('id = ? AND id >= 0', [int.tryParse(key)]),
        'pilot_profile' => ('id = ?', [PilotProfile.rowId]),
        _ => ('sync_id = ?', [key]),
      };

  /// The name, the same on every device, of row [id] of [table].
  Future<String?> _nameOf(String table, int id) async {
    if (table == 'airports' && id >= 0) return 'oa:$id';
    final column = table == 'icao_aircrafts' ? _icaoKey : 'sync_id';
    final rows = await _select('SELECT $column AS k FROM $table WHERE id = ?', [
      id,
    ]);
    return rows.isEmpty ? null : rows.first['k'] as String?;
  }

  /// The row of [table] that [name] (from [_nameOf]) stands for here.
  Future<int?> _idOf(String table, String name) async {
    if (table == 'airports' && name.startsWith('oa:')) {
      return int.tryParse(name.substring(3));
    }
    final (where, args) = _match(table, _aliases[(table, name)] ?? name);
    final rows = await _select('SELECT id FROM $table WHERE $where', args);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  final _columnCache = <String, Set<String>>{};

  /// The columns of [table].
  Future<Set<String>> _columns(String table) async => _columnCache[table] ??= {
    for (final c in await _select('PRAGMA table_info("$table")'))
      c['name'] as String,
  };

  /// Whether row [key] of [entity] was deleted on this device, with a
  /// `deleted` of at least [min] (see [schema]).
  Future<bool> _deleted(String entity, String key, int min) async =>
      (await _select(
        'SELECT 1 FROM sync_rows WHERE entity = ? AND key = ? AND deleted >= ?',
        [entity, key, min],
      )).isNotEmpty;

  /// The [values] that are columns of [table]: names from another device
  /// never reach the SQL otherwise.
  Future<Map<String, Object?>> _columnsOf(
    String table,
    Map<String, Object?> values,
  ) async {
    final columns = await _columns(table);
    return {
      for (final MapEntry(:key, :value) in values.entries)
        if (columns.contains(key) && key != 'id' && key != 'sync_id')
          key: value,
    };
  }

  /// Updates row [id] of [table], or inserts one when null. Returns its id.
  Future<int> _upsert(
    String table,
    int? id,
    Map<String, Object?> values,
  ) async {
    final names = [for (final c in values.keys) '"$c"'];
    if (id != null) {
      if (values.isEmpty) return id;
      await _db.customStatement(
        'UPDATE $table SET ${names.map((c) => '$c = ?').join(', ')} '
        'WHERE id = ?',
        [...values.values, id],
      );
      return id;
    }
    return _db.customInsert(
      'INSERT INTO $table (${names.join(', ')}) '
      'VALUES (${List.filled(names.length, '?').join(', ')})',
      variables: [for (final v in values.values) Variable(v)],
    );
  }

  /// Pictures the logbook names, with where each is kept.
  Future<List<(String, PhotoStore)>> _referencedFiles() async => [
    for (final MapEntry(key: (table, column), value: store) in _files.entries)
      for (final r in await _select(
        'SELECT DISTINCT $column AS name FROM $table '
        'WHERE $column IS NOT NULL',
      ))
        // Names come from other devices too: never let one leave the folder.
        if (r['name'] case final String name
            when name.isNotEmpty &&
                !name.contains('/') &&
                !name.contains(r'\') &&
                name != '..')
          (name, store),
  ];

  Future<List<Map<String, Object?>>> _select(
    String sql, [
    List<Object?> args = const [],
  ]) async => [
    for (final row
        in await _db
            .customSelect(sql, variables: [for (final a in args) Variable(a)])
            .get())
      row.data,
  ];

  static Uint8List _encode(Object json) =>
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json))));

  static Map<String, Object?> _decode(Uint8List bytes) =>
      jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>;
}

/// A row of a state file.
class _Row {
  const _Row({
    required this.entity,
    required this.key,
    required this.stamp,
    required this.device,
    required this.deleted,
    this.values,
    this.children,
  });

  final String entity;
  final String key;
  final int stamp;
  final String device;
  final bool deleted;

  /// Its columns, with references as names.
  final Map<String, Object?>? values;

  /// A flight's crew as [person, role], or a licence's ratings.
  final List<Object?>? children;
}
