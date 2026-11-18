import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// Repository for airport data access using Drift's reactive queries
class AirportRepository {
  AirportRepository(this._database);
  final LogbookDatabase _database;

  /// Stream of airports matching a search query. [customOnly] keeps the
  /// user's own airports, newest first.
  Stream<List<Airport>> searchAirports({
    String query = '',
    String? countryCode,
    AirportType? type,
    bool customOnly = false,
    int limit = 100,
  }) {
    final statement = _database.select(_database.airports)..limit(limit);

    final tokens = searchTokens(query);
    if (tokens.isNotEmpty) {
      statement.where(
        (a) => sqlMatchesAllTokens(tokens, [
          a.name,
          a.ident,
          a.icaoCode,
          a.iataCode,
          a.municipality,
        ]),
      );
    }

    if (customOnly) {
      statement
        ..where((a) => a.id.isSmallerThanValue(0))
        ..orderBy([(a) => OrderingTerm.asc(a.id)]);
    }

    if (countryCode != null) {
      statement.where((a) => a.isoCountry.equals(countryCode));
    }

    if (type != null) {
      statement.where((a) => a.type.equals(type.index));
    }

    return statement.watch();
  }

  /// Stream of the airports flights departed from or arrived at, the most
  /// recently used first.
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
          // By id too, so pages agree on airports last used by the same
          // flight.
          ..orderBy([
            OrderingTerm.desc(lastUsed),
            OrderingTerm.asc(_database.airports.id),
          ])
          ..limit(limit, offset: offset);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_database.airports)).toList();
    });
  }

  /// Stream of the [limit] airports nearest to the coordinates, nearest
  /// first, among those within [delta] degrees of them.
  Stream<List<Airport>> watchAirportsNear(
    double latitude,
    double longitude, {
    double delta = 2.0,
    int limit = 20,
  }) {
    // Flat-earth distance: plenty to rank airports a couple of degrees away.
    final lonScale = cos(latitude * pi / 180);
    Expression<double> squaredDistance($AirportsTable a) {
      final dLat = a.latitudeDeg - Variable(latitude);
      final dLon = (a.longitudeDeg - Variable(longitude)) * Variable(lonScale);
      return dLat * dLat + dLon * dLon;
    }

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
          ..orderBy([(a) => OrderingTerm.asc(squaredDistance(a))])
          ..limit(limit))
        .watch();
  }

  /// Stream of countries, by name
  Stream<List<Country>> watchCountries() {
    return (_database.select(
      _database.countries,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
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
      country: refs.isoCountry.prefetchedData?.singleOrNull,
      region: refs.isoRegion.prefetchedData?.singleOrNull,
      runways: refs.runwayRefs.prefetchedData ?? [],
      frequencies: refs.frequencyRefs.prefetchedData ?? [],
    );
  }

  /// The airport with [id], or null.
  Future<Airport?> getAirport(int id) {
    return (_database.select(
      _database.airports,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
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

  /// Stream of the regions of a country, by name.
  Stream<List<Region>> watchRegions(String countryCode) {
    return (_database.select(_database.regions)
          ..where((r) => r.isoCountry.equals(countryCode))
          ..orderBy([(r) => OrderingTerm.asc(r.name)]))
        .watch();
  }

  /// Whether another airport than [exceptId] is already known by [ident]
  /// (case-insensitively), which must stay unique.
  Future<bool> isIdentTaken(String ident, {int? exceptId}) async {
    final query = _database.select(_database.airports)
      ..where((a) => a.ident.upper().equals(ident.trim().toUpperCase()));
    if (exceptId != null) query.where((a) => a.id.equals(exceptId).not());
    return (await (query..limit(1)).get()).isNotEmpty;
  }

  /// Adds an airport of the user's own and returns its (negative) id. The
  /// companion's id is ignored.
  Future<int> addCustomAirport(AirportsCompanion airport) {
    return _database.transaction(() async {
      final lowest = await _database
          .customSelect('SELECT MIN(id) AS id FROM airports')
          .map((row) => row.read<int?>('id'))
          .getSingle();
      final id = min(lowest ?? 0, 0) - 1;
      await _database
          .into(_database.airports)
          .insert(airport.copyWith(id: Value(id)));
      return id;
    });
  }

  /// Updates an airport of the user's own. OurAirports airports aren't
  /// touched: the next sync would undo the change anyway.
  Future<void> updateCustomAirport(int id, AirportsCompanion airport) async {
    if (id >= 0) throw ArgumentError.value(id, 'id', 'Not a custom airport');
    await (_database.update(
      _database.airports,
    )..where((a) => a.id.equals(id))).write(airport.copyWith(id: Value(id)));
  }

  /// Deletes an airport of the user's own, unless a flight uses it. Returns
  /// whether it was deleted.
  Future<bool> deleteCustomAirport(int id) async {
    if (id >= 0) throw ArgumentError.value(id, 'id', 'Not a custom airport');
    return _database.transaction(() async {
      if (await isAirportReferencedInFlights(id)) return false;
      await (_database.delete(
        _database.airports,
      )..where((a) => a.id.equals(id))).go();
      return true;
    });
  }

  /// Stream of how many flights departed from or arrived at each airport,
  /// by airport id. A flight that lands where it took off counts once;
  /// airports no flight used are left out.
  Stream<Map<int, int>> watchFlightCounts() {
    return _database
        .customSelect(
          'SELECT airport, COUNT(*) AS flights FROM ('
          'SELECT id, departure AS airport FROM flights '
          'WHERE departure IS NOT NULL '
          'UNION SELECT id, arrival AS airport FROM flights '
          'WHERE arrival IS NOT NULL'
          ') GROUP BY airport',
          readsFrom: {_database.flights},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('airport'): row.read<int>('flights'),
          },
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
