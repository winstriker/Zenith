import 'dart:io';
import 'package:flutter/foundation.dart';
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

  List<Airport> _airports = [];
  List<AirportFrequency> _frequencies = [];
  List<Runway> _runways = [];
  List<Country> _countries = [];
  List<Region> _regions = [];
  bool _loaded = false;
  String? _error;

  bool get isLoaded => _loaded;
  String? get error => _error;

  List<Airport> get airports => List.unmodifiable(_airports);
  List<Country> get countries => List.unmodifiable(_countries);
  List<Region> get regions => List.unmodifiable(_regions);

  List<String> get airportTypes =>
      _airports.map((a) => a.type).toSet().toList()..sort();

  Future<void> loadData({bool forceRefresh = false}) async {
    final dir = await getApplicationDocumentsDirectory();

    try {
      if (!forceRefresh) {
        await _loadFromCache(dir);
      }

      if (!_loaded) {
        await _downloadAndParse(dir);
        _loaded = true;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> _loadFromCache(Directory dir) async {
    final airportFile = File('${dir.path}/$_airportsFile');
    final freqFile = File('${dir.path}/$_frequenciesFile');
    final runwayFile = File('${dir.path}/$_runwaysFile');
    final countryFile = File('${dir.path}/$_countriesFile');
    final regionFile = File('${dir.path}/$_regionsFile');

    if (!await airportFile.exists() ||
        !await freqFile.exists() ||
        !await runwayFile.exists() ||
        !await countryFile.exists() ||
        !await regionFile.exists()) {
      return;
    }

    final airportData = await airportFile.readAsString();
    final freqData = await freqFile.readAsString();
    final runwayData = await runwayFile.readAsString();
    final countryData = await countryFile.readAsString();
    final regionData = await regionFile.readAsString();

    await compute(_parseAll, _ParseArgs(
      airportData: airportData,
      freqData: freqData,
      runwayData: runwayData,
      countryData: countryData,
      regionData: regionData,
    )).then((result) {
      _airports = result.airports;
      _frequencies = result.frequencies;
      _runways = result.runways;
      _countries = result.countries;
      _regions = result.regions;
      _loaded = true;
    });
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

      await Future.wait([
        File('${dir.path}/$_airportsFile').writeAsString(airportData),
        File('${dir.path}/$_frequenciesFile').writeAsString(freqData),
        File('${dir.path}/$_runwaysFile').writeAsString(runwayData),
        File('${dir.path}/$_countriesFile').writeAsString(countryData),
        File('${dir.path}/$_regionsFile').writeAsString(regionData),
      ]);

      final result = await compute(_parseAll, _ParseArgs(
        airportData: airportData,
        freqData: freqData,
        runwayData: runwayData,
        countryData: countryData,
        regionData: regionData,
      ));

      _airports = result.airports;
      _frequencies = result.frequencies;
      _runways = result.runways;
      _countries = result.countries;
      _regions = result.regions;
    } finally {
      client.close();
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

  List<AirportFrequency> getFrequencies(String airportRef) {
    return _frequencies
        .where((f) => f.airportRef == airportRef)
        .toList()
      ..sort((a, b) => a.type.compareTo(b.type));
  }

  List<Runway> getRunways(String airportRef) {
    return _runways.where((r) => r.airportRef == airportRef).toList();
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
  final String countryData;
  final String regionData;
  const _ParseArgs({
    required this.airportData,
    required this.freqData,
    required this.runwayData,
    required this.countryData,
    required this.regionData,
  });
}

class _ParseResult {
  final List<Airport> airports;
  final List<AirportFrequency> frequencies;
  final List<Runway> runways;
  final List<Country> countries;
  final List<Region> regions;
  const _ParseResult({
    required this.airports,
    required this.frequencies,
    required this.runways,
    required this.countries,
    required this.regions,
  });
}

_ParseResult _parseAll(_ParseArgs args) {
  final airports = _parseAirports(args.airportData);
  final frequencies = _parseFrequencies(args.freqData);
  final runways = _parseRunways(args.runwayData);
  final countries = _parseCountries(args.countryData);
  final regions = _parseRegions(args.regionData);
  return _ParseResult(
    airports: airports,
    frequencies: frequencies,
    runways: runways,
    countries: countries,
    regions: regions,
  );
}

List<Airport> _parseAirports(String data) {
  final rows = parseCsv(data);
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

List<AirportFrequency> _parseFrequencies(String data) {
  final rows = parseCsv(data);
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

List<Runway> _parseRunways(String data) {
  final rows = parseCsv(data);
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

List<Country> _parseCountries(String data) {
  final rows = parseCsv(data);
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

List<Region> _parseRegions(String data) {
  final rows = parseCsv(data);
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
