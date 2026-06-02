import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/airport.dart';
import '../models/airport_frequency.dart';
import '../models/runway.dart';
import '../models/country.dart';
import '../models/region.dart';
import '../utils/csv_parser.dart';

class AirportService {
  static final AirportService _instance = AirportService._();
  factory AirportService() => _instance;
  AirportService._();

  static const _baseUrl = 'https://davidmegginson.github.io/ourairports-data';
  static const _airportsFile = 'airports.csv';
  static const _frequenciesFile = 'airport-frequencies.csv';
  static const _runwaysFile = 'runways.csv';
  static const _countriesFile = 'countries.csv';
  static const _regionsFile = 'regions.csv';
  static const _stampFile = '.last_download';

  List<Airport> _airports = [];
  List<Country> _countries = [];
  List<Region> _regions = [];
  bool _loaded = false;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;

  LazyBox<String>? _freqBox;
  LazyBox<String>? _runwayBox;
  LazyBox<String>? _countryBox;
  LazyBox<String>? _regionBox;
  Box<Airport>? _airportBox;
  bool _hiveReady = false;
  List<String> _airportTypes = [];
  int _dataVersion = 0;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  bool get isRefreshing => _refreshing;
  String? get error => _error;

  List<Airport> get airports => List.unmodifiable(_airports);
  List<Country> get countries => List.unmodifiable(_countries);
  List<Region> get regions => List.unmodifiable(_regions);

  int get dataVersion => _dataVersion;

  List<String> get airportTypes => _airportTypes;

  void _updateAirportTypes() {
    _airportTypes = _airports.map((a) => a.type).toSet().toList()..sort();
    _dataVersion++;
  }

  List<Country> _deriveCountries() {
    final codes = _airports
        .where((a) => a.isoCountry != null && a.isoCountry!.length == 2)
        .map((a) => a.isoCountry!)
        .toSet()
        .toList()
      ..sort();
    return codes.map((c) => Country(
      id: c,
      code: c,
      name: '$c',
      continent: '',
    )).toList();
  }

  String countryFlag(String code) {
    if (code.length != 2) return '';
    final flag = String.fromCharCodes(
      code.toUpperCase().runes.map((r) => 0x1F1E6 - 65 + r),
    );
    return flag;
  }

  String countryLabel(Country c) {
    final flag = countryFlag(c.code);
    return flag.isNotEmpty ? '$flag ${c.name}' : c.name;
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List.from(_listeners)) {
      listener();
    }
  }

  Future<void> initHive() async {
    if (_hiveReady) return;
    _freqBox = await Hive.openLazyBox<String>('airport_frequencies');
    _runwayBox = await Hive.openLazyBox<String>('airport_runways');
    _countryBox = await Hive.openLazyBox<String>('airport_countries');
    _regionBox = await Hive.openLazyBox<String>('airport_regions');
    _airportBox = await Hive.openBox<Airport>('airports');
    _hiveReady = true;
  }

  Future<void> loadData() async {
    if (_loading) return;
    await initHive();
    _loading = true;
    _error = null;
    _notify();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheOk = await _tryLoadCache(dir);

      if (cacheOk) {
        _loaded = true;
        _loading = false;
        _notify();

        final stale = await _isCacheStale(dir);
        if (stale) {
          _refreshing = true;
          _notify();
          await _downloadAndParse(dir);
          _refreshing = false;
          _notify();
        }
      } else {
        await _downloadAndParse(dir);
        _loaded = true;
        _loading = false;
        _error = null;
        _notify();
      }
    } catch (e) {
      _loading = false;
      _refreshing = false;
      if (!_loaded) {
        _error = e.toString();
      }
      _notify();
    }
  }

  Future<bool> _tryLoadCache(Directory dir) async {
    // Try loading from Hive first
    if (_airportBox!.isNotEmpty) {
      _airports = _airportBox!.values.toList();
      await _rebuildCountriesAndRegions();
      _updateAirportTypes();
      return true;
    }

    // Fallback: parse CSV files and populate Hive
    final stampFile = File('${dir.path}/$_stampFile');
    final airportFile = File('${dir.path}/$_airportsFile');
    if (!await stampFile.exists() || !await airportFile.exists()) {
      return false;
    }

    final airportData = await airportFile.readAsString();
    final airportRows = parseCsv(airportData);
    _airports = _parseAirportsFromRows(airportRows);
    _updateAirportTypes();

    final countryFile = File('${dir.path}/$_countriesFile');
    final regionFile = File('${dir.path}/$_regionsFile');
    if (await countryFile.exists()) {
      _countries = _parseCountriesFromRows(parseCsv(await countryFile.readAsString()));
    }
    if (await regionFile.exists()) {
      _regions = _parseRegionsFromRows(parseCsv(await regionFile.readAsString()));
    }

    await _storeAirports(_airports);
    await _storeCountries(_countries);
    await _storeRegions(_regions);
    return true;
  }

  Future<bool> _isCacheStale(Directory dir) async {
    final stampFile = File('${dir.path}/$_stampFile');
    if (!await stampFile.exists()) return true;
    try {
      final content = await stampFile.readAsString();
      final lastDownload = DateTime.parse(content.trim());
      return lastDownload.isBefore(_lastUpdateCutoff());
    } catch (_) {
      return true;
    }
  }

  DateTime _lastUpdateCutoff() {
    final now = DateTime.now().toUtc();
    final todayMidnight = DateTime.utc(now.year, now.month, now.day);
    if (now.isAfter(todayMidnight) || now.isAtSameMomentAs(todayMidnight)) {
      return todayMidnight;
    }
    return todayMidnight.subtract(const Duration(days: 1));
  }

  Future<void> _downloadAndParse(Directory dir) async {
    final client = http.Client();
    try {
      final results = await Future.wait([
        client.get(Uri.parse('$_baseUrl/$_airportsFile')),
        client.get(Uri.parse('$_baseUrl/$_frequenciesFile')),
        client.get(Uri.parse('$_baseUrl/$_runwaysFile')),
        client.get(Uri.parse('$_baseUrl/$_countriesFile')),
        client.get(Uri.parse('$_baseUrl/$_regionsFile')),
      ]);

      final airportData = results[0].body;
      final freqData = results[1].body;
      final runwayData = results[2].body;
      final countryData = results[3].body;
      final regionData = results[4].body;

      // Write CSVs to disk as backup
      await Future.wait([
        File('${dir.path}/$_airportsFile').writeAsString(airportData),
        File('${dir.path}/$_frequenciesFile').writeAsString(freqData),
        File('${dir.path}/$_runwaysFile').writeAsString(runwayData),
        File('${dir.path}/$_countriesFile').writeAsString(countryData),
        File('${dir.path}/$_regionsFile').writeAsString(regionData),
        File('${dir.path}/$_stampFile').writeAsString(
          DateTime.now().toUtc().toIso8601String(),
        ),
      ]);

      final result = await compute(_parseAll, _ParseArgs(
        airportData: airportData,
        freqData: freqData,
        runwayData: runwayData,
      ));

      _airports = result.airports;
      _countries = _parseCountriesFromRows(parseCsv(countryData));
      _regions = _parseRegionsFromRows(parseCsv(regionData));
      _updateAirportTypes();

      await Future.wait([
        _storeAirports(result.airports),
        _storeCountries(_countries),
        _storeRegions(_regions),
        _storeFrequencies(result.frequencies),
        _storeRunways(result.runways),
      ]);
      await _rebuildCountriesAndRegions();
    } finally {
      client.close();
    }
  }

  Future<void> _storeAirports(List<Airport> airports) async {
    await _airportBox!.clear();
    for (final a in airports) {
      await _airportBox!.put(a.id, a);
    }
  }

  Future<void> _storeCountries(List<Country> countries) async {
    await _countryBox!.clear();
    for (final c in countries) {
      final data = jsonEncode({
        'id': c.id,
        'code': c.code,
        'name': c.name,
        'continent': c.continent,
        'wikipediaLink': c.wikipediaLink,
        'keywords': c.keywords,
      });
      await _countryBox!.put(c.code, data);
    }
  }

  Future<void> _storeRegions(List<Region> regions) async {
    await _regionBox!.clear();
    for (final r in regions) {
      final data = jsonEncode({
        'id': r.id,
        'code': r.code,
        'localCode': r.localCode,
        'name': r.name,
        'continent': r.continent,
        'isoCountry': r.isoCountry,
        'wikipediaLink': r.wikipediaLink,
        'keywords': r.keywords,
      });
      await _regionBox!.put(r.code, data);
    }
  }

  Future<void> _rebuildCountriesAndRegions() async {
    if (_countryBox!.isNotEmpty) {
      final list = <Country>[];
      for (final key in _countryBox!.keys) {
        final raw = await _countryBox!.get(key);
        if (raw == null) continue;
        final m = jsonDecode(raw) as Map<String, dynamic>;
        list.add(Country(
          id: m['id'] as String,
          code: m['code'] as String,
          name: m['name'] as String,
          continent: m['continent'] as String,
          wikipediaLink: m['wikipediaLink'] as String?,
          keywords: m['keywords'] as String?,
        ));
      }
      _countries = list;
    } else {
      _countries = _deriveCountries();
      await _storeCountries(_countries);
    }
    if (_regionBox!.isNotEmpty) {
      final list = <Region>[];
      for (final key in _regionBox!.keys) {
        final raw = await _regionBox!.get(key);
        if (raw == null) continue;
        final m = jsonDecode(raw) as Map<String, dynamic>;
        list.add(Region(
          id: m['id'] as String,
          code: m['code'] as String,
          localCode: m['localCode'] as String,
          name: m['name'] as String,
          continent: m['continent'] as String,
          isoCountry: m['isoCountry'] as String,
          wikipediaLink: m['wikipediaLink'] as String?,
          keywords: m['keywords'] as String?,
        ));
      }
      _regions = list;
    }
  }

  Future<void> _storeFrequencies(List<AirportFrequency> freqs) async {
    final byRef = <String, List<List<dynamic>>>{};
    for (final f in freqs) {
      byRef.putIfAbsent(f.airportRef, () => []).add([
        f.id, f.airportIdent, f.type, f.description, f.frequencyMhz,
      ]);
    }
    await _freqBox!.clear();
    final keys = byRef.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      await _freqBox!.put(keys[i], jsonEncode(byRef[keys[i]]));
    }
  }

  Future<void> _storeRunways(List<Runway> runways) async {
    final byRef = <String, List<List<dynamic>>>{};
    for (final r in runways) {
      byRef.putIfAbsent(r.airportRef, () => []).add([
        r.id, r.airportIdent, r.lengthFt, r.widthFt, r.surface, r.lighted, r.closed,
        r.leIdent, r.leLatitudeDeg, r.leLongitudeDeg, r.leElevationFt,
        r.leHeadingDegT, r.leDisplacedThresholdFt,
        r.heIdent, r.heLatitudeDeg, r.heLongitudeDeg, r.heElevationFt,
        r.heHeadingDegT, r.heDisplacedThresholdFt,
      ]);
    }
    await _runwayBox!.clear();
    final keys = byRef.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      await _runwayBox!.put(keys[i], jsonEncode(byRef[keys[i]]));
    }
  }

  List<Airport> searchAirports({
    String? query,
    String? countryCode,
    String? type,
  }) {
    var result = _airports.where((a) => a.type != 'closed').toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((a) =>
        a.name.toLowerCase().contains(q) ||
        (a.municipality?.toLowerCase().contains(q) ?? false) ||
        a.ident.toLowerCase().contains(q) ||
        (a.icaoCode?.toLowerCase().contains(q) ?? false) ||
        (a.iataCode?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (countryCode != null && countryCode.isNotEmpty) {
      result = result.where((a) => a.isoCountry == countryCode).toList();
    }

    if (type != null && type.isNotEmpty) {
      result = result.where((a) => a.type == type).toList();
    }

    return result;
  }

  Future<List<AirportFrequency>> getFrequencies(String airportRef) async {
    final raw = await _freqBox!.get(airportRef);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final freqs = list.map((e) {
      final row = e as List<dynamic>;
      return AirportFrequency(
        id: row[0] as String,
        airportRef: airportRef,
        airportIdent: row[1] as String,
        type: row[2] as String,
        description: row[3] as String,
        frequencyMhz: (row[4] as num).toDouble(),
      );
    }).toList();
    freqs.sort((a, b) => a.type.compareTo(b.type));
    return freqs;
  }

  Future<List<Runway>> getRunways(String airportRef) async {
    final raw = await _runwayBox!.get(airportRef);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final row = e as List<dynamic>;
      return Runway(
        id: row[0] as String,
        airportRef: airportRef,
        airportIdent: row[1] as String,
        lengthFt: row[2] as double?,
        widthFt: row[3] as double?,
        surface: row[4] as String?,
        lighted: row[5] is bool ? row[5] as bool : (row[5] as num?)?.toInt() == 1,
        closed: row[6] is bool ? row[6] as bool : (row[6] as num?)?.toInt() == 1,
        leIdent: row[7] as String?,
        leLatitudeDeg: row[8] as double?,
        leLongitudeDeg: row[9] as double?,
        leElevationFt: row[10] as double?,
        leHeadingDegT: row[11] as double?,
        leDisplacedThresholdFt: row[12] as double?,
        heIdent: row[13] as String?,
        heLatitudeDeg: row[14] as double?,
        heLongitudeDeg: row[15] as double?,
        heElevationFt: row[16] as double?,
        heHeadingDegT: row[17] as double?,
        heDisplacedThresholdFt: row[18] as double?,
      );
    }).toList();
  }

  Country? getCountry(String? code) {
    if (code == null) return null;
    try {
      return _countries.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  Region? getRegion(String? code) {
    if (code == null) return null;
    try {
      return _regions.firstWhere((r) => r.code == code);
    } catch (_) {
      return null;
    }
  }

  Airport? getAirportById(String id) {
    try {
      return _airports.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Airport? getAirportByIdent(String ident) {
    try {
      return _airports.firstWhere((a) => a.ident == ident);
    } catch (_) {
      return null;
    }
  }
}

class _ParseArgs {
  final String airportData;
  final String freqData;
  final String runwayData;
  const _ParseArgs({
    required this.airportData,
    required this.freqData,
    required this.runwayData,
  });
}

class _ParseResult {
  final List<Airport> airports;
  final List<AirportFrequency> frequencies;
  final List<Runway> runways;
  const _ParseResult({
    required this.airports,
    required this.frequencies,
    required this.runways,
  });
}

_ParseResult _parseAll(_ParseArgs args) {
  final airportRows = parseCsv(args.airportData);
  final freqRows = parseCsv(args.freqData);
  final runwayRows = parseCsv(args.runwayData);

  return _ParseResult(
    airports: _parseAirportsFromRows(airportRows),
    frequencies: _parseFrequenciesFromRows(freqRows),
    runways: _parseRunwaysFromRows(runwayRows),
  );
}

List<Airport> _parseAirportsFromRows(List<List<String>> rows) {
  if (rows.length < 2) return [];
  final airports = <Airport>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 19) continue;
    airports.add(Airport(
      id: row[0],
      ident: row[1],
      type: row[2],
      name: row[3],
      latitudeDeg: _parseDouble(row[4]),
      longitudeDeg: _parseDouble(row[5]),
      elevationFt: _parseDouble(row[6]),
      continent: _nullIfEmpty(row[7]),
      isoCountry: _nullIfEmpty(row[8]),
      isoRegion: _nullIfEmpty(row[9]),
      municipality: _nullIfEmpty(row[10]),
      scheduledService: row.length > 11 ? row[11] == 'yes' : false,
      icaoCode: _nullIfEmpty(row.length > 12 ? row[12] : ''),
      iataCode: _nullIfEmpty(row.length > 13 ? row[13] : ''),
      gpsCode: _nullIfEmpty(row.length > 14 ? row[14] : ''),
      localCode: _nullIfEmpty(row.length > 15 ? row[15] : ''),
      homeLink: _nullIfEmpty(row.length > 16 ? row[16] : ''),
      wikipediaLink: _nullIfEmpty(row.length > 17 ? row[17] : ''),
      keywords: _nullIfEmpty(row.length > 18 ? row[18] : ''),
    ));
  }
  return airports;
}

List<AirportFrequency> _parseFrequenciesFromRows(List<List<String>> rows) {
  if (rows.isEmpty) return [];
  final frequencies = <AirportFrequency>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 6) continue;
    frequencies.add(AirportFrequency(
      id: row[0],
      airportRef: row[1],
      airportIdent: row[2],
      type: row[3],
      description: row[4],
      frequencyMhz: _parseDouble(row[5]) ?? 0,
    ));
  }
  return frequencies;
}

List<Runway> _parseRunwaysFromRows(List<List<String>> rows) {
  if (rows.isEmpty) return [];
  final runways = <Runway>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 20) continue;
    runways.add(Runway(
      id: row[0],
      airportRef: row[1],
      airportIdent: row[2],
      lengthFt: _parseDouble(row[3]),
      widthFt: _parseDouble(row[4]),
      surface: _nullIfEmpty(row[5]),
      lighted: row.length > 6 ? row[6] == '1' : false,
      closed: row.length > 7 ? row[7] == '1' : false,
      leIdent: _nullIfEmpty(row.length > 8 ? row[8] : ''),
      leLatitudeDeg: _parseDouble(row.length > 9 ? row[9] : ''),
      leLongitudeDeg: _parseDouble(row.length > 10 ? row[10] : ''),
      leElevationFt: _parseDouble(row.length > 11 ? row[11] : ''),
      leHeadingDegT: _parseDouble(row.length > 12 ? row[12] : ''),
      leDisplacedThresholdFt: _parseDouble(row.length > 13 ? row[13] : ''),
      heIdent: _nullIfEmpty(row.length > 14 ? row[14] : ''),
      heLatitudeDeg: _parseDouble(row.length > 15 ? row[15] : ''),
      heLongitudeDeg: _parseDouble(row.length > 16 ? row[16] : ''),
      heElevationFt: _parseDouble(row.length > 17 ? row[17] : ''),
      heHeadingDegT: _parseDouble(row.length > 18 ? row[18] : ''),
      heDisplacedThresholdFt: _parseDouble(row.length > 19 ? row[19] : ''),
    ));
  }
  return runways;
}

List<Country> _parseCountriesFromRows(List<List<String>> rows) {
  if (rows.isEmpty) return [];
  final countries = <Country>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 4) continue;
    countries.add(Country(
      id: row[0],
      code: row[1],
      name: row[2],
      continent: row[3],
      wikipediaLink: _nullIfEmpty(row.length > 4 ? row[4] : ''),
      keywords: _nullIfEmpty(row.length > 5 ? row[5] : ''),
    ));
  }
  return countries;
}

List<Region> _parseRegionsFromRows(List<List<String>> rows) {
  if (rows.isEmpty) return [];
  final regions = <Region>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 6) continue;
    regions.add(Region(
      id: row[0],
      code: row[1],
      localCode: row[2],
      name: row[3],
      continent: row[4],
      isoCountry: row[5],
      wikipediaLink: _nullIfEmpty(row.length > 6 ? row[6] : ''),
      keywords: _nullIfEmpty(row.length > 7 ? row[7] : ''),
    ));
  }
  return regions;
}

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
