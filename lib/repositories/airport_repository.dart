import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

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
  Stream<List<Airport>> watchRecentAirports({int limit = 5}) {
    // This is a simplified version - in practice you'd want a more efficient query
    // For now, we'll use a computed stream from recent flights
    return Stream.value(<Airport>[]);
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
    final query = _database.select(_database.airports).join([
      leftOuterJoin(
        _database.countries,
        _database.countries.code.equalsExp(_database.airports.isoCountry),
      ),
      leftOuterJoin(
        _database.regions,
        _database.regions.code.equalsExp(_database.airports.isoRegion),
      ),
    ])..where(_database.airports.id.equals(airportId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final airport = row.readTable(_database.airports);
    final country = row.readTable(_database.countries);
    final region = row.readTable(_database.regions);

    final runwaysQuery = _database.select(_database.runways)
      ..where((r) => r.airport.equals(airportId));
    final runways = await runwaysQuery.get();

    final frequenciesQuery = _database.select(_database.frequencies)
      ..where((f) => f.airport.equals(airportId));
    final frequencies = await frequenciesQuery.get();

    return AirportWithEverything(
      airport: airport,
      country: country,
      region: region,
      runways: runways,
      frequencies: frequencies,
    );
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
