import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../services/database.dart';

/// Repository for airport data access using Drift's reactive queries
class AirportRepository {
  AirportRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of airports matching a search query
  Stream<List<Airport>> searchAirports({
    String query = '',
    String? countryCode,
    AirportType? type,
    int limit = 100,
  }) {
    final statement = _database.select(_database.airports)..limit(limit);

    if (query.isNotEmpty) {
      final term = '%$query%';
      statement.where(
        (a) =>
            a.name.like(term) |
            a.ident.like(term) |
            a.icaoCode.like(term) |
            a.iataCode.like(term) |
            a.municipality.like(term),
      );
    }

    if (countryCode != null) {
      statement.where((a) => a.isoCountry.equals(countryCode));
    }

    if (type != null) {
      statement.where((a) => a.type.equals(type.index));
    }

    return statement.watch();
  }

  /// Stream of recent airports (from recent flights)
  Stream<List<Airport>> watchRecentAirports({int limit = 5, int offset = 0}) {
    final lastUsed = _database.flights.departureTime.max();

    final query =
        _database.select(_database.airports).join([
            innerJoin(
              _database.flights,
              _database.airports.id.equalsExp(_database.flights.departure) |
                  _database.airports.id.equalsExp(_database.flights.arrival),
            ),
          ])
          ..groupBy([_database.airports.id])
          ..orderBy([OrderingTerm.desc(lastUsed)])
          ..limit(limit, offset: offset);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_database.airports)).toList();
    });
  }

  /// Stream of airports near coordinates
  Stream<List<Airport>> watchAirportsNear(
    double latitude,
    double longitude, {
    double delta = 2.0,
    int limit = 20,
  }) {
    return (_database.select(_database.airports)
          ..where(
            (a) => a.latitudeDeg.isBetweenValues(
              latitude - delta,
              latitude + delta,
            ),
          )
          ..where(
            (a) => a.longitudeDeg.isBetweenValues(
              longitude - delta,
              longitude + delta,
            ),
          )
          ..limit(limit))
        .watch();
  }

  /// Stream of all airports alphabetical
  Stream<List<Airport>> watchAllAirportsAlphabetical({int limit = 100}) {
    return (_database.select(_database.airports)
          ..orderBy([(a) => OrderingTerm.asc(a.name)])
          ..limit(limit))
        .watch();
  }

  /// Stream of countries
  Stream<List<Country>> watchCountries() {
    return _database.select(_database.countries).watch();
  }

  /// Stream of complete airport data with runways and frequencies
  Future<AirportWithEverything?> getCompleteAirportData(int airportId) async {
    final result = await _database.managers.airports
        .filter((a) => a.id(airportId))
        .withReferences(
          (prefetch) => prefetch(
            isoCountry: true,
            isoRegion: true,
            runwayRefs: true,
            frequencyRefs: true,
          ),
        )
        .getSingleOrNull();

    if (result == null) {
      return null;
    }

    final (airport, refs) = result;
    return AirportWithEverything(
      airport: airport,
      country: refs.isoCountry.prefetchedData!.single,
      region: refs.isoRegion.prefetchedData!.single,
      runways: refs.runwayRefs.prefetchedData ?? [],
      frequencies: refs.frequencyRefs.prefetchedData ?? [],
    );
  }

  /// One-off search (no stream), e.g. for type-ahead lookups.
  Future<List<Airport>> findAirports(String query, {int limit = 15}) {
    return _database.searchAirports(query: query, limit: limit);
  }

  /// Airports most recently used in flights.
  Future<List<Airport>> getRecentAirports({int limit = 5}) {
    return _database.getRecentAirports(limit: limit);
  }

  /// Airports inside a lat/lon square centered on the given point.
  Future<List<Airport>?> getAirportsWithinSquare(
    double latitude,
    double longitude, {
    required double delta,
  }) {
    return _database.getAirportsWithinSquare(latitude, longitude, delta: delta);
  }

  /// Check if airport is referenced in flights
  Future<bool> isAirportReferencedInFlights(int airportId) async {
    final departureCountQuery = _database.select(_database.flights)
      ..where((f) => f.departure.equals(airportId));
    final departureCount = await departureCountQuery.get();
    if (departureCount.isNotEmpty) return true;

    final arrivalCountQuery = _database.select(_database.flights)
      ..where((f) => f.arrival.equals(airportId));
    final arrivalCount = await arrivalCountQuery.get();
    return arrivalCount.isNotEmpty;
  }
}

final airportRepositoryProvider = Provider<AirportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AirportRepository(db);
});
