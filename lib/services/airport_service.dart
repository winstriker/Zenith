import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/csv_parser.dart';
import 'database.dart';

/// Called with the overall fraction (0–1) of the current stage and a
/// human-readable description of what is happening.
typedef SyncProgressCallback = void Function(double fraction, String message);

class AirportsService {
  AirportsService(this.database) {
    isLocating = true;
    _locate()
        .then((pos) {
          position = pos;
        })
        .whenComplete(() {
          isLocating = false;
        });
  }
  final logger = Logger("Airports Service");
  final LogbookDatabase database;

  static const _baseUrl = 'https://davidmegginson.github.io/ourairports-data';
  static const _countriesFile = 'countries.csv';
  static const _regionsFile = 'regions.csv';
  static const _airportsFile = 'airports.csv';
  static const _runwaysFile = 'runways.csv';
  static const _frequenciesFile = 'airport-frequencies.csv';
  static const _files = [
    _countriesFile,
    _regionsFile,
    _airportsFile,
    _runwaysFile,
    _frequenciesFile,
  ];
  static const _lastTimeUpdatedPrefsKey = 'last_time_updated';

  // Share of the overall progress bar given to each stage.
  static const _downloadEnd = 0.40;
  static const _parseEnd = 0.50;

  /// Live progress of the OurAirports sync.
  final progress = ValueNotifier<AirportSyncProgress>(
    const AirportSyncProgress(AirportSyncPhase.idle),
  );

  var isLocating = false;
  Position? position;

  bool get isBusy => progress.value.isRunning;

  void dispose() => progress.dispose();

  void _setProgress(
    AirportSyncPhase phase, {
    double? fraction,
    String message = '',
    Object? error,
  }) {
    progress.value = AirportSyncProgress(
      phase,
      fraction: fraction,
      message: message,
      error: error,
    );
  }

  static final _syncLogger = Logger("Airports Sync");

  Future<void> loadData({bool forceDownload = false}) async {
    if (isBusy) return;
    // Mark as running synchronously so concurrent calls bail out above.
    _setProgress(
      AirportSyncPhase.downloading,
      fraction: 0,
      message: 'Preparing download…',
    );

    final prefs = await SharedPreferences.getInstance();
    if (!forceDownload && _downloadedToday(prefs)) {
      _syncLogger.info("Already downloaded today!");
      _setProgress(
        AirportSyncPhase.done,
        fraction: 1,
        message: 'Airport data is up to date',
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    // autoUncompress off: bytes received then match Content-Length (the
    // compressed size), so the % is accurate. Gunzip happens in the isolate.
    final client = HttpClient()..autoUncompress = false;
    try {
      final bodies = await _downloadAll(client);

      _setProgress(
        AirportSyncPhase.parsing,
        fraction: _downloadEnd,
        message: 'Processing airport data…',
      );
      final parsed = await _parseInBackground(bodies);

      _setProgress(
        AirportSyncPhase.saving,
        fraction: _parseEnd,
        message: 'Saving airport data…',
      );
      final summary = await syncAirportData(
        database,
        parsed,
        onProgress: (f, message) => _setProgress(
          AirportSyncPhase.saving,
          fraction: _parseEnd + f * (1 - _parseEnd),
          message: message,
        ),
      );

      await prefs.setInt(
        _lastTimeUpdatedPrefsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      _syncLogger.info('$summary in ${stopwatch.elapsedMilliseconds} ms');
      _setProgress(
        AirportSyncPhase.done,
        fraction: 1,
        message: 'Airport data updated',
      );
    } catch (e, st) {
      logger.severe('Airport data sync failed', e, st);
      _setProgress(
        AirportSyncPhase.error,
        message: 'Could not download airport data',
        error: e,
      );
    } finally {
      client.close(force: true);
    }
  }

  static bool _downloadedToday(SharedPreferences prefs) {
    final lastTimeUpdated = prefs.getInt(_lastTimeUpdatedPrefsKey);
    if (lastTimeUpdated == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(lastTimeUpdated);
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return !last.isBefore(todayMidnight);
  }

  /// Downloads every CSV in parallel, reporting byte-level progress.
  Future<List<_Download>> _downloadAll(HttpClient client) {
    final received = List<int>.filled(_files.length, 0);
    final totals = List<int?>.filled(_files.length, null);
    final headersReceived = List<bool>.filled(_files.length, false);
    var completed = 0;
    final throttle = Stopwatch()..start();

    void report({bool force = false}) {
      if (!force && throttle.elapsedMilliseconds < 100) return;
      throttle.reset();
      final receivedBytes = received.fold<int>(0, (a, b) => a + b);
      final allTotalsKnown =
          headersReceived.every((h) => h) && totals.every((t) => t != null);
      final double fraction;
      final String message;
      if (allTotalsKnown) {
        final totalBytes = totals.fold<int>(0, (a, b) => a + b!);
        fraction = totalBytes == 0 ? 0 : receivedBytes / totalBytes;
        message =
            'Downloading airport data — '
            '${_mb(receivedBytes)} / ${_mb(totalBytes)} MB';
      } else {
        fraction = completed / _files.length;
        message = 'Downloading airport data — ${_mb(receivedBytes)} MB';
      }
      _setProgress(
        AirportSyncPhase.downloading,
        fraction: fraction.clamp(0, 1) * _downloadEnd,
        message: message,
      );
    }

    Future<_Download> download(int i) async {
      final request = await client.getUrl(Uri.parse('$_baseUrl/${_files[i]}'));
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'HTTP ${response.statusCode} while downloading ${_files[i]}',
        );
      }
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final length = response.contentLength;
      totals[i] = length > 0 ? length : null;
      headersReceived[i] = true;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        received[i] += chunk.length;
        report();
      }
      completed++;
      report(force: true);
      return _Download(
        builder.takeBytes(),
        gzipped: encoding?.toLowerCase() == 'gzip',
      );
    }

    return Future.wait([for (var i = 0; i < _files.length; i++) download(i)]);
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  /// Static on purpose: a closure created inside an instance method shares
  /// its context with sibling closures and may capture `this` (DB, ports,
  /// listeners), which can't be sent to another isolate.
  static Future<ParsedAirportData> _parseInBackground(List<_Download> bodies) =>
      Isolate.run(() => _decodeAndParse(bodies));

  /// Runs in a background isolate: gunzips and decodes the downloaded bytes
  /// (same order as [_files]) and parses them into rows ready to be written.
  static ParsedAirportData _decodeAndParse(List<_Download> bodies) {
    String text(int i) {
      final d = bodies[i];
      return utf8.decode(
        d.gzipped ? gzip.decode(d.bytes) : d.bytes,
        allowMalformed: true,
      );
    }

    return parseAirportData(
      countriesCsv: text(0),
      regionsCsv: text(1),
      airportsCsv: text(2),
      runwaysCsv: text(3),
      frequenciesCsv: text(4),
    );
  }

  /// Parses the OurAirports CSV files. Pure and synchronous, so it can run
  /// in an isolate.
  static ParsedAirportData parseAirportData({
    required String countriesCsv,
    required String regionsCsv,
    required String airportsCsv,
    required String runwaysCsv,
    required String frequenciesCsv,
  }) {
    final countries = <CountriesCompanion>[];
    for (final row in parseCsv(countriesCsv).skip(1)) {
      if (row.length < 6) continue;
      final id = _parseInt(row[0]);
      if (id == null) continue;
      countries.add(
        CountriesCompanion.insert(
          id: Value(id),
          code: row[1],
          name: row[2],
          continent: row[3],
          wikipediaLink: Value(_nullIfEmpty(row[4])),
          keywords: Value(_nullIfEmpty(row[5])),
        ),
      );
    }

    final regions = <RegionsCompanion>[];
    for (final row in parseCsv(regionsCsv).skip(1)) {
      if (row.length < 8) continue;
      final id = _parseInt(row[0]);
      if (id == null) continue;
      regions.add(
        RegionsCompanion.insert(
          id: Value(id),
          code: row[1],
          localCode: Value(_nullIfEmpty(row[2])),
          name: row[3],
          continent: row[4],
          isoCountry: row[5],
          wikipediaLink: Value(_nullIfEmpty(row[6])),
          keywords: Value(_nullIfEmpty(row[7])),
        ),
      );
    }

    final airports = <Airport>[];
    final seenIds = <int>{};
    final seenIdents = <String>{};
    for (final row in parseCsv(airportsCsv).skip(1)) {
      if (row.length < 19) continue;
      final id = _parseInt(row[0]);
      if (id == null || !seenIds.add(id)) continue;
      // `ident` is UNIQUE: drop duplicates instead of failing the sync.
      final ident = seenIdents.add(row[1]) ? row[1] : null;
      airports.add(
        Airport(
          id: id,
          ident: ident,
          type: AirportType.fromCsvString(row[2]),
          name: row[3],
          latitudeDeg: _parseDouble(row[4]),
          longitudeDeg: _parseDouble(row[5]),
          elevationFt: _parseInt(row[6]),
          continent: row[7],
          isoCountry: row[8],
          isoRegion: row[9],
          municipality: row[10],
          scheduledService: row[11] == 'yes',
          icaoCode: row[12],
          iataCode: row[13],
          gpsCode: row[14],
          localCode: row[15],
          homeLink: row[16],
          wikipediaLink: row[17],
          keywords: row[18],
        ),
      );
    }

    final runways = <RunwaysCompanion>[];
    for (final row in parseCsv(runwaysCsv).skip(1)) {
      if (row.length < 20) continue;
      final id = _parseInt(row[0]);
      final airport = _parseInt(row[1]);
      if (id == null || airport == null) continue;
      runways.add(
        RunwaysCompanion.insert(
          id: Value(id),
          airport: airport,
          lengthFt: Value(_parseInt(row[3])),
          widthFt: Value(_parseInt(row[4])),
          surface: Value(_nullIfEmpty(row[5])),
          lighted: Value(row[6] == '1'),
          closed: Value(row[7] == '1'),
          leIdent: Value(_nullIfEmpty(row[8])),
          leLatitudeDeg: Value(_parseDouble(row[9])),
          leLongitudeDeg: Value(_parseDouble(row[10])),
          leElevationFt: Value(_parseInt(row[11])),
          leHeadingDegT: Value(_parseDouble(row[12])),
          leDisplacedThresholdFt: Value(_parseInt(row[13])),
          heIdent: Value(_nullIfEmpty(row[14])),
          heLatitudeDeg: Value(_parseDouble(row[15])),
          heLongitudeDeg: Value(_parseDouble(row[16])),
          heElevationFt: Value(_parseInt(row[17])),
          heHeadingDegT: Value(_parseDouble(row[18])),
          heDisplacedThresholdFt: Value(_parseInt(row[19])),
        ),
      );
    }

    final frequencies = <FrequenciesCompanion>[];
    for (final row in parseCsv(frequenciesCsv).skip(1)) {
      if (row.length < 6) continue;
      final id = _parseInt(row[0]);
      final airport = _parseInt(row[1]);
      if (id == null || airport == null) continue;
      frequencies.add(
        FrequenciesCompanion.insert(
          id: Value(id),
          airport: airport,
          type: Value(_nullIfEmpty(row[3])),
          description: Value(_nullIfEmpty(row[4])),
          frequencyMhz: Value(_nullIfEmpty(row[5])),
        ),
      );
    }

    return ParsedAirportData(
      countries: countries,
      regions: regions,
      airports: airports,
      runways: runways,
      frequencies: frequencies,
    );
  }

  static const _chunkSize = 5000;

  /// Writes [data] into [db] in a single transaction, so a failure leaves the
  /// previous data untouched.
  ///
  /// Airports referenced by flights are never deleted; when OurAirports
  /// changes them they are updated in place (same id, so flights keep
  /// pointing at them).
  static Future<AirportSyncSummary> syncAirportData(
    LogbookDatabase db,
    ParsedAirportData data, {
    SyncProgressCallback? onProgress,
  }) {
    // Progress is measured in rows; airports are counted once for the diff.
    final totalUnits = max(
      1,
      data.countries.length +
          data.regions.length +
          data.airports.length +
          data.runways.length +
          data.frequencies.length,
    );
    var doneUnits = 0;
    void advance(int units, String message) {
      doneUnits += units;
      onProgress?.call(min(1, doneUnits / totalUnits), message);
    }

    return db.transaction(() async {
      // Countries & regions: small, full replace.
      await db.countries.deleteAll();
      await _insertChunked(
        db,
        db.countries,
        data.countries,
        (n) => advance(n, 'Saving countries'),
      );
      await db.regions.deleteAll();
      await _insertChunked(
        db,
        db.regions,
        data.regions,
        (n) => advance(n, 'Saving regions'),
      );

      // Airports: diff against what's stored.
      final referenced = await db.getReferencedAirportIds();
      final existing = {
        for (final a in await db.select(db.airports).get()) a.id: a,
      };
      final newIds = <int>{for (final a in data.airports) a.id};
      final newIdents = <String>{
        for (final a in data.airports)
          if (a.ident != null) a.ident!,
      };

      final toDelete = <int>[];
      final keptIdentClashes = <int>[];
      var kept = 0;
      for (final old in existing.values) {
        if (newIds.contains(old.id)) continue;
        if (referenced.contains(old.id)) {
          kept++;
          if (old.ident != null && newIdents.contains(old.ident)) {
            keptIdentClashes.add(old.id);
          }
        } else {
          toDelete.add(old.id);
        }
      }

      final toUpsert = <Airport>[];
      final identChanged = <int>[];
      var added = 0;
      var updated = 0;
      for (final airport in data.airports) {
        final old = existing[airport.id];
        if (old == null) {
          added++;
          toUpsert.add(airport);
        } else if (old != airport) {
          updated++;
          toUpsert.add(airport);
          if (old.ident != airport.ident) identChanged.add(airport.id);
        }
      }

      // Free up idents before writing so the UNIQUE(ident) constraint can't
      // fire: removed rows go away, and rows whose ident is about to move
      // (or is taken by a new airport) are cleared first.
      for (final chunk in _chunks(toDelete)) {
        await (db.delete(db.airports)..where((a) => a.id.isIn(chunk))).go();
      }
      for (final chunk in _chunks([...identChanged, ...keptIdentClashes])) {
        await (db.update(db.airports)..where((a) => a.id.isIn(chunk))).write(
          const AirportsCompanion(ident: Value(null)),
        );
      }

      // Unchanged airports still count towards progress.
      final airportUnitsPerWrite = toUpsert.isEmpty
          ? 0.0
          : data.airports.length / toUpsert.length;
      if (toUpsert.isEmpty) advance(data.airports.length, 'Saving airports');
      var written = 0;
      var reportedUnits = 0;
      for (final chunk in _chunks(toUpsert)) {
        await db.batch((b) => b.insertAllOnConflictUpdate(db.airports, chunk));
        written += chunk.length;
        final units = (written * airportUnitsPerWrite).round();
        advance(
          units - reportedUnits,
          'Saving airports $written / ${toUpsert.length}',
        );
        reportedUnits = units;
      }

      // Runways & frequencies: full replace, skipping orphans.
      final airportIds = {...newIds, ...existing.keys}..removeAll(toDelete);
      await db.runways.deleteAll();
      await _insertChunked(
        db,
        db.runways,
        data.runways.where((r) => airportIds.contains(r.airport.value)),
        (n) => advance(n, 'Saving runways'),
        total: data.runways.length,
      );
      await db.frequencies.deleteAll();
      await _insertChunked(
        db,
        db.frequencies,
        data.frequencies.where((f) => airportIds.contains(f.airport.value)),
        (n) => advance(n, 'Saving frequencies'),
        total: data.frequencies.length,
      );

      return AirportSyncSummary(
        added: added,
        updated: updated,
        deleted: toDelete.length,
        kept: kept,
      );
    });
  }

  static Future<void> _insertChunked<T extends Table, D>(
    LogbookDatabase db,
    TableInfo<T, D> table,
    Iterable<Insertable<D>> rows,
    void Function(int count) onUnits, {
    int? total,
  }) async {
    final list = rows.toList();
    for (final chunk in _chunks(list)) {
      await db.batch((b) => b.insertAll(table, chunk));
      onUnits(chunk.length);
    }
    // Rows that were filtered out still count towards progress.
    if (total != null && total > list.length) onUnits(total - list.length);
  }

  static Iterable<List<E>> _chunks<E>(List<E> list) sync* {
    for (var i = 0; i < list.length; i += _chunkSize) {
      yield list.sublist(i, min(i + _chunkSize, list.length));
    }
  }

  Future<AirportWithEverything?> getCompleteAirportData(int id) async {
    return database.getCompleteAirportData(id);
  }

  Future<List<AirportWithDistance>> getNearAirports({
    int limit = 20,
    bool relocate = false,
  }) async {
    if (relocate || position == null) {
      isLocating = true;
      try {
        position = await _locate();
      } catch (e) {
        isLocating = false;
        _syncLogger.log(
          Level.WARNING,
          "Failed to get location, falling back to alphabetical: $e",
        );
        return getAirportsAlphabetical(limit: limit);
      }
      isLocating = false;
    }
    return getAirportsNearCoordinates(
      position!.latitude,
      position!.longitude,
      limit: limit,
    );
  }

  Future<List<AirportWithDistance>> getNearAirportsWithFallback({
    int limit = 20,
    bool relocate = false,
  }) async {
    if (relocate || position == null) {
      isLocating = true;
      try {
        position = await _locate();
      } catch (e) {
        isLocating = false;
        _syncLogger.log(
          Level.WARNING,
          "Failed to get location, falling back to alphabetical: $e",
        );
        return getAirportsAlphabetical(limit: limit);
      }
      isLocating = false;
    }
    return getAirportsNearCoordinates(
      position!.latitude,
      position!.longitude,
      limit: limit,
    );
  }

  Future<List<AirportWithDistance>> getAirportsNearCoordinates(
    double latitude,
    double longitude, {
    int limit = 20,
  }) async {
    final candidates = await database.getAirportsWithinSquare(
      latitude,
      longitude,
    );
    if (candidates == null) {
      return List<AirportWithDistance>.empty();
    }
    final List<AirportWithDistance> sorted = candidates.map((airport) {
      final d = _distance(
        latitude,
        longitude,
        airport.latitudeDeg!,
        airport.longitudeDeg!,
      );
      return AirportWithDistance(airport, d);
    }).toList();

    sorted.sort((a, b) => a.distance.compareTo(b.distance));

    return sorted.take(limit).toList();
  }

  Future<List<Airport>> searchAirports({
    String query = '',
    String? countryCode,
    AirportType? type,
    int limit = 100,
  }) {
    return database.searchAirports(
      query: query,
      countryCode: countryCode,
      type: type,
      limit: limit,
    );
  }

  Future<List<AirportWithDistance>> getAirportsAlphabetical({
    int limit = 100,
  }) async {
    final airports = await database.getAllAirportsAlphabetical(limit: limit);
    return airports.map((a) => AirportWithDistance(a, -1)).toList();
  }

  Future<List<Country>> getCountriesList() {
    return database.countries
        .select(distinct: true)
        .get()
        .then(
          (countries) => countries..sort((a, b) => a.name.compareTo(b.name)),
        );
  }
}

/// Raw body of one downloaded file.
class _Download {
  const _Download(this.bytes, {required this.gzipped});
  final Uint8List bytes;
  final bool gzipped;
}

enum AirportSyncPhase { idle, downloading, parsing, saving, done, error }

/// Snapshot of the OurAirports sync progress.
@immutable
class AirportSyncProgress {
  const AirportSyncProgress(
    this.phase, {
    this.fraction,
    this.message = '',
    this.error,
  });

  final AirportSyncPhase phase;

  /// Overall completion between 0 and 1, or null when unknown.
  final double? fraction;
  final String message;
  final Object? error;

  bool get isRunning =>
      phase == AirportSyncPhase.downloading ||
      phase == AirportSyncPhase.parsing ||
      phase == AirportSyncPhase.saving;

  /// Rounded percentage, or null when [fraction] is unknown.
  int? get percent => fraction == null ? null : (fraction! * 100).round();
}

/// Rows parsed from the OurAirports CSVs, ready to be written.
class ParsedAirportData {
  const ParsedAirportData({
    required this.countries,
    required this.regions,
    required this.airports,
    required this.runways,
    required this.frequencies,
  });

  final List<CountriesCompanion> countries;
  final List<RegionsCompanion> regions;
  final List<Airport> airports;
  final List<RunwaysCompanion> runways;
  final List<FrequenciesCompanion> frequencies;
}

class AirportSyncSummary {
  const AirportSyncSummary({
    required this.added,
    required this.updated,
    required this.deleted,
    required this.kept,
  });

  final int added;
  final int updated;
  final int deleted;

  /// Airports removed from OurAirports but kept because flights use them.
  final int kept;

  @override
  String toString() =>
      'Airport sync: $added added, $updated updated, $deleted deleted, '
      '$kept kept (used in flights)';
}

double _distance(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return radius * 2 * asin(sqrt(a));
}

double _toRad(double deg) => deg * pi / 180;

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

int? _parseInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Future<Position?> _locate() async {
  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever ||
      perm == LocationPermission.unableToDetermine) {
    return null;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  return pos;
}
