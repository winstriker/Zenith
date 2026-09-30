import 'dart:math';

import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/csv_parser.dart';
import 'database.dart';

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

  static Future<Map<int, Airport>> _parseAirportsToMap(
    http.Response response,
  ) async {
    final rows = parseCsv(response.body);

    final airports = <int, Airport>{};
    for (final row in rows.skip(1)) {
      final id = _parseInt(row[0])!;
      airports[id] = Airport(
        id: id,
        ident: row[1],
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
      );
    }
    return airports;
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

  static Future<Map<String, Country>> _parseCountriesToMap(
    http.Response response,
  ) async {
    final rows = parseCsv(response.body);

    final countries = <String, Country>{};
    for (final row in rows.skip(1)) {
      final code = row[1];
      countries[code] = Country(
        id: _parseInt(row[0])!,
        code: code,
        name: row[2],
        continent: row[3],
        wikipediaLink: _nullIfEmpty(row[4]),
        keywords: _nullIfEmpty(row[5]),
      );
    }
    return countries;
  }

  static Future<Map<String, Region>> _parseRegionsToMap(
    http.Response response,
  ) async {
    final rows = parseCsv(response.body);
    if (rows.length < 2) return {};

    final regions = <String, Region>{};
    for (final row in rows.skip(1)) {
      final code = row[1];
      regions[code] = Region(
        id: _parseInt(row[0])!,
        code: code,
        localCode: _nullIfEmpty(row[2]),
        name: row[3],
        continent: row[4],
        isoCountry: row[5],
        wikipediaLink: _nullIfEmpty(row[6]),
        keywords: _nullIfEmpty(row[7]),
      );
    }
    return regions;
  }

  static final _syncLogger = Logger("Airports Sync");

  static Future<void> _syncAirportsWithSmartUpdate(
    Map<int, Airport> newAirports,
    LogbookDatabase database,
  ) async {
    final existingAirportsMap = {
      for (var a in await database.select(database.airports).get()) a.id: a,
    };

    final newIds = newAirports.keys.toSet();
    final existingIds = existingAirportsMap.keys.toSet();

    final addedIds = newIds.difference(existingIds);
    final removedIds = existingIds.difference(newIds);
    final commonIds = newIds.intersection(existingIds);

    for (final id in removedIds) {
      final isReferenced = await database.isAirportReferencedInFlights(id);
      if (!isReferenced) {
        await (database.delete(
          database.airports,
        )..where((a) => a.id.equals(id))).go();
        _syncLogger.log(Level.INFO, "Removed unreferenced airport: $id");
      } else {
        _syncLogger.log(Level.INFO, "Keeping referenced airport: $id");
      }
    }

    for (final id in addedIds) {
      final airport = newAirports[id]!;
      await database
          .into(database.airports)
          .insert(
            AirportsCompanion.insert(
              id: Value(airport.id),
              ident: Value(airport.ident),
              type: airport.type,
              name: Value(airport.name),
              latitudeDeg: Value(airport.latitudeDeg),
              longitudeDeg: Value(airport.longitudeDeg),
              elevationFt: Value(airport.elevationFt),
              continent: airport.continent,
              isoCountry: airport.isoCountry,
              isoRegion: airport.isoRegion,
              municipality: Value(airport.municipality),
              scheduledService: Value(airport.scheduledService),
              icaoCode: Value(airport.icaoCode),
              iataCode: Value(airport.iataCode),
              gpsCode: Value(airport.gpsCode),
              localCode: Value(airport.localCode),
              homeLink: Value(airport.homeLink),
              wikipediaLink: Value(airport.wikipediaLink),
              keywords: Value(airport.keywords),
            ),
          );
      _syncLogger.log(
        Level.INFO,
        "Added new airport: ${airport.ident} (${airport.id})",
      );
    }

    final commonIdsList = commonIds.toList();
    if (commonIdsList.isNotEmpty) {
      final referencedMap = await database.areAirportsReferencedInFlights(
        commonIdsList,
      );

      for (final id in commonIdsList) {
        final newAirport = newAirports[id]!;
        final existingAirport = existingAirportsMap[id]!;
        final isReferenced = referencedMap[id] ?? false;

        final hasChanges =
            existingAirport.ident != newAirport.ident ||
            existingAirport.type != newAirport.type ||
            existingAirport.name != newAirport.name ||
            existingAirport.latitudeDeg != newAirport.latitudeDeg ||
            existingAirport.longitudeDeg != newAirport.longitudeDeg ||
            existingAirport.elevationFt != newAirport.elevationFt ||
            existingAirport.continent != newAirport.continent ||
            existingAirport.isoCountry != newAirport.isoCountry ||
            existingAirport.isoRegion != newAirport.isoRegion ||
            existingAirport.municipality != newAirport.municipality ||
            existingAirport.scheduledService != newAirport.scheduledService ||
            existingAirport.icaoCode != newAirport.icaoCode ||
            existingAirport.iataCode != newAirport.iataCode ||
            existingAirport.gpsCode != newAirport.gpsCode ||
            existingAirport.localCode != newAirport.localCode ||
            existingAirport.homeLink != newAirport.homeLink ||
            existingAirport.wikipediaLink != newAirport.wikipediaLink ||
            existingAirport.keywords != newAirport.keywords;

        if (hasChanges) {
          if (!isReferenced) {
            await (database.update(
              database.airports,
            )..where((a) => a.id.equals(id))).write(
              AirportsCompanion(
                ident: Value(newAirport.ident),
                type: Value(newAirport.type),
                name: Value(newAirport.name),
                latitudeDeg: Value(newAirport.latitudeDeg),
                longitudeDeg: Value(newAirport.longitudeDeg),
                elevationFt: Value(newAirport.elevationFt),
                continent: Value(newAirport.continent),
                isoCountry: Value(newAirport.isoCountry),
                isoRegion: Value(newAirport.isoRegion),
                municipality: Value(newAirport.municipality),
                scheduledService: Value(newAirport.scheduledService),
                icaoCode: Value(newAirport.icaoCode),
                iataCode: Value(newAirport.iataCode),
                gpsCode: Value(newAirport.gpsCode),
                localCode: Value(newAirport.localCode),
                homeLink: Value(newAirport.homeLink),
                wikipediaLink: Value(newAirport.wikipediaLink),
                keywords: Value(newAirport.keywords),
              ),
            );
            _syncLogger.log(
              Level.INFO,
              "Updated airport: ${newAirport.ident} ($id)",
            );
          } else {
            final newId = await database
                .into(database.airports)
                .insert(
                  AirportsCompanion.insert(
                    ident: Value(newAirport.ident),
                    type: newAirport.type,
                    name: Value(newAirport.name),
                    latitudeDeg: Value(newAirport.latitudeDeg),
                    longitudeDeg: Value(newAirport.longitudeDeg),
                    elevationFt: Value(newAirport.elevationFt),
                    continent: newAirport.continent,
                    isoCountry: newAirport.isoRegion,
                    isoRegion: newAirport.isoRegion,
                    municipality: Value(newAirport.municipality),
                    scheduledService: Value(newAirport.scheduledService),
                    icaoCode: Value(newAirport.icaoCode),
                    iataCode: Value(newAirport.iataCode),
                    gpsCode: Value(newAirport.gpsCode),
                    localCode: Value(newAirport.localCode),
                    homeLink: Value(newAirport.homeLink),
                    wikipediaLink: Value(newAirport.wikipediaLink),
                    keywords: Value(newAirport.keywords),
                  ),
                );
            _syncLogger.log(
              Level.INFO,
              "Created new version of referenced airport: ${newAirport.ident} (old: $id, new: $newId)",
            );
          }
        }
      }
    }
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
          _syncLogger.log(Level.INFO, "Already downloaded today!");
          return;
        }
      }
    }

    final client = http.Client();
    try {
      status = AirportServiceStatus.downloadingCountries;
      _notify();
      final countriesResponse = await client.get(
        Uri.parse('$_baseUrl/$_countriesFile'),
      );

      status = AirportServiceStatus.downloadingRegions;
      _notify();
      final regionsResponse = await client.get(
        Uri.parse('$_baseUrl/$_regionsFile'),
      );

      status = AirportServiceStatus.downloadingAirports;
      _notify();
      final airportsResponse = await client.get(
        Uri.parse('$_baseUrl/$_airportsFile'),
      );

      final newCountries = await _parseCountriesToMap(countriesResponse);
      final newRegions = await _parseRegionsToMap(regionsResponse);
      final newAirports = await _parseAirportsToMap(airportsResponse);

      final countriesData = newCountries.values
          .map(
            (c) => CountriesCompanion.insert(
              id: Value(c.id),
              code: c.code,
              name: c.name,
              continent: c.continent,
              wikipediaLink: Value(c.wikipediaLink),
              keywords: Value(c.keywords),
            ),
          )
          .toList();

      final regionsData = newRegions.values
          .map(
            (r) => RegionsCompanion.insert(
              id: Value(r.id),
              code: r.code,
              localCode: Value(r.localCode),
              name: r.name,
              continent: r.continent,
              isoCountry: r.isoCountry,
              wikipediaLink: Value(r.wikipediaLink),
              keywords: Value(r.keywords),
            ),
          )
          .toList();

      final frequenciesResponse = await client.get(
        Uri.parse('$_baseUrl/$_frequenciesFile'),
      );
      final runwaysResponse = await client.get(
        Uri.parse('$_baseUrl/$_runwaysFile'),
      );

      status = AirportServiceStatus.downloadingRunwaysAndFrequencies;
      _notify();

      await database.computeWithDatabase(
        computation: (database) async {
          await database.countries.deleteAll();
          await database.batch((batch) {
            database.countries.insertAll(countriesData);
          });

          await database.regions.deleteAll();
          await database.batch((batch) {
            database.regions.insertAll(regionsData);
          });

          await AirportsService._syncAirportsWithSmartUpdate(
            newAirports,
            database,
          );

          await Future.wait([
            AirportsService._parseFrequencies(frequenciesResponse, database),
            AirportsService._parseRunways(runwaysResponse, database),
          ]);
        },
        connect: (connection) {
          return LogbookDatabase(connection);
        },
      );
    } catch (e) {
      status = AirportServiceStatus.error;
      logger.log(Level.SEVERE, 'Airport data sync failed', e);
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
