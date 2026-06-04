import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:logbook/services/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/csv_parser.dart';
import 'dart:math';
import 'package:logging/logging.dart';

class AirportsService {
  final logger = Logger("Airports Service");
  final LogbookDatabase database;

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

  static const _baseUrl = 'https://davidmegginson.github.io/ourairports-data';
  static const _airportsFile = 'airports.csv';
  static const _frequenciesFile = 'airport-frequencies.csv';
  static const _runwaysFile = 'runways.csv';
  static const _countriesFile = 'countries.csv';
  static const _regionsFile = 'regions.csv';
  static const _lastTimeUpdatedPrefsKey = 'last_time_updated';
  List<Function> callbacks = [];

  var status = AirportServiceStatus.ready;
  var isLocating = false;
  Position? position;

  void addListener(Function fun) {
    callbacks.add(fun);
  }

  void removeListener(Function fun) {
    callbacks.remove(fun);
  }

  void _notify() {
    for (var fun in callbacks) {
      fun();
    }
  }

  static Future<void> _parseAirports(
    http.Response response,
    LogbookDatabase database,
  ) async {
    final rows = parseCsv(response.body);

    final airports = rows
        .skip(1)
        .map(
          (row) => AirportsCompanion.insert(
            id: Value(_parseInt(row[0])!),
            ident: Value(row[1]),
            type: AirportType.fromCsvString(row[2]),
            name: Value(row[3]),
            latitudeDeg: Value(_parseDouble(row[4])),
            longitudeDeg: Value(_parseDouble(row[5])),
            elevationFt: Value(_parseInt(row[6])),
            continent: row[7],
            isoCountry: row[8],
            isoRegion: row[9],
            municipality: Value(row[10]),
            scheduledService: Value(row[11] == 'yes'),
            icaoCode: Value(row[12]),
            iataCode: Value(row[13]),
            gpsCode: Value(row[14]),
            localCode: Value(row[15]),
            homeLink: Value(row[16]),
            wikipediaLink: Value(row[17]),
            keywords: Value(row[18]),
          ),
        );

    await database.airports.deleteAll();

    await database.batch((batch) {
      database.airports.insertAll(airports);
    });
  }

  static Future<void> _parseRunways(
    http.Response response,
    LogbookDatabase database,
  ) async {
    final rows = parseCsv(response.body);
    if (rows.length < 2) return;
    final runways = rows.skip(1).map((row) {
      return RunwaysCompanion.insert(
        id: Value(_parseInt(row[0])!),
        airport: _parseInt(row[1])!,
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
      );
    });

    await database.runways.deleteAll();
    await database.batch((batch) {
      database.runways.insertAll(runways);
    });
  }

  static Future<void> _parseFrequencies(
    http.Response response,
    LogbookDatabase database,
  ) async {
    final rows = parseCsv(response.body);
    if (rows.length < 2) return;

    final frequencies = rows.skip(1).map((row) {
      return FrequenciesCompanion.insert(
        id: Value(_parseInt(row[0])!),
        airport: _parseInt(row[1])!,
        type: Value(_nullIfEmpty(row[3])),
        description: Value(_nullIfEmpty(row[4])),
        frequencyMhz: Value(_nullIfEmpty(row[5])),
      );
    });
    await database.frequencies.deleteAll();

    await database.batch((batch) {
      database.frequencies.insertAll(frequencies);
    });
  }

  static Future<void> _parseCountries(
    http.Response response,
    LogbookDatabase database,
  ) async {
    final rows = parseCsv(response.body);

    final countries = rows.skip(1).map((row) {
      return CountriesCompanion.insert(
        id: Value(_parseInt(row[0])!),
        code: row[1],
        name: row[2],
        continent: row[3],
        wikipediaLink: Value(_nullIfEmpty(row[4])),
        keywords: Value(_nullIfEmpty(row[5])),
      );
    });

    await database.countries.deleteAll();
    await database.batch((batch) {
      database.countries.insertAll(countries);
    });
  }

  static Future<void> _parseRegions(
    http.Response response,
    LogbookDatabase database,
  ) async {
    final rows = parseCsv(response.body);
    if (rows.length < 2) return;

    final regions = rows.skip(1).map((row) {
      return RegionsCompanion.insert(
        id: Value(_parseInt(row[0])!),
        code: row[1],
        localCode: Value(_nullIfEmpty(row[2])),
        name: row[3],
        continent: row[4],
        isoCountry: row[5],
        wikipediaLink: Value(_nullIfEmpty(row[6])),
        keywords: Value(_nullIfEmpty(row[7])),
      );
    });

    await database.regions.deleteAll();
    await database.batch((batch) {
      database.regions.insertAll(regions);
    });
  }

  Future<void> loadData({bool forceDownload = false}) async {
    if (status.type == StatusType.downloading) return;
    final prefs = await SharedPreferences.getInstance();
    if (!forceDownload) {
      final lastTimeUpdated = prefs.getInt(_lastTimeUpdatedPrefsKey);
      if (lastTimeUpdated != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastTimeUpdated);
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        if (todayMidnight.isBefore(last) ||
            todayMidnight.isAtSameMomentAs(last)) {
          logger.log(Level.INFO, "Already downloaded today!");
          return;
        }
      }
    }

    final client = http.Client();
    try {
      status = AirportServiceStatus.downloadingAirports;
      final responses = await Future.wait([
        client.get(Uri.parse('$_baseUrl/$_countriesFile')),
        client.get(Uri.parse('$_baseUrl/$_regionsFile')),
        client.get(Uri.parse('$_baseUrl/$_airportsFile')),
        client.get(Uri.parse('$_baseUrl/$_frequenciesFile')),
        client.get(Uri.parse('$_baseUrl/$_runwaysFile')),
      ]);

      await database.computeWithDatabase(
        computation: (database) async {
          await AirportsService._parseCountries(responses[0], database);
          await AirportsService._parseRegions(responses[1], database);
          await AirportsService._parseAirports(responses[2], database);
          await Future.wait([
            AirportsService._parseFrequencies(responses[3], database),
            AirportsService._parseRunways(responses[4], database),
          ]);
        },
        connect: (connection) {
          return LogbookDatabase(connection);
        },
      );
    } catch (e) {
      status = AirportServiceStatus.error;
      print(e);
      _notify();
      return;
    } finally {
      client.close();
    }

    await prefs.setInt(
      _lastTimeUpdatedPrefsKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    status = AirportServiceStatus.ready;
    _notify();
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
      } finally {
        isLocating = false;
      }
    }
    return getAirportsNearCoordinates(position!.latitude, position!.longitude);
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

  Future<List<Country>> getCountriesList() {
    return database.countries.select(distinct: true).get();
  }
}

enum AirportServiceStatus {
  ready(message: "Ready", type: StatusType.ready),
  downloadingCountries(
    message: "Downloading Countries",
    type: StatusType.downloading,
  ),
  downloadingRegions(
    message: "Downloading Regions",
    type: StatusType.downloading,
  ),
  downloadingAirports(
    message: "Downloading Airports",
    type: StatusType.downloading,
  ),
  downloadingRunwaysAndFrequencies(
    message: "Downloading Runways and Frequencies",
    type: StatusType.downloading,
  ),
  error(message: "Error occurred while downloading!", type: StatusType.error);

  const AirportServiceStatus({required this.message, required this.type});

  final String message;
  final StatusType type;
}

enum StatusType { ready, downloading, error }

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

Future<Position> _locate() async {
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  return pos;
}
