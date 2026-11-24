import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// Airports, with the countries and regions they are in.
class AirportRepository {
  AirportRepository(this._database);
  final LogbookDatabase _database;

  /// Airports with an ICAO code, or of the user's own.
  // The sync stores a missing code as '': NULL and '' both fail this.
  static Expression<bool> _icaoOrCustom($AirportsTable a) =>
      a.icaoCode.isNotValue('') | a.id.isSmallerThanValue(0);

  /// Airports whose type isn't one of [types].
  static Expression<bool> Function($AirportsTable) _notOfTypes(
    Set<AirportType> types,
  ) =>
      (a) => a.type.isNotIn([for (final t in types) t.index]);

  /// Stream of airports matching a search query. [customOnly] keeps the
  /// user's own airports, newest first; [icaoOnly] those with an ICAO code
  /// or of the user's own. [excludedTypes] are left out unless [type] asks
  /// for one.
  Stream<List<Airport>> searchAirports({
    String query = '',
    String? countryCode,
    AirportType? type,
    bool customOnly = false,
    bool icaoOnly = false,
    Set<AirportType> excludedTypes = const {},
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
    } else if (excludedTypes.isNotEmpty) {
      statement.where(_notOfTypes(excludedTypes));
    }

    if (icaoOnly) statement.where(_icaoOrCustom);

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
    bool icaoOnly = false,
    Set<AirportType> excludedTypes = const {},
  }) {
    // Flat-earth distance: plenty to rank airports a couple of degrees away.
    final lonScale = cos(latitude * pi / 180);
    Expression<double> squaredDistance($AirportsTable a) {
      final dLat = a.latitudeDeg - Variable(latitude);
      final dLon = (a.longitudeDeg - Variable(longitude)) * Variable(lonScale);
      return dLat * dLat + dLon * dLon;
    }

    final statement = _database.select(_database.airports);
    if (icaoOnly) statement.where(_icaoOrCustom);
    if (excludedTypes.isNotEmpty) statement.where(_notOfTypes(excludedTypes));
    return (statement
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

  /// The first [limit] airports with a position that match every filter,
  /// inside [bounds] when given, the biggest airports first. [usedOnly]
  /// keeps those a flight used, [customOnly] the user's own, and [icaoOnly]
  /// those with an ICAO code or of the user's own. [excludedTypes] are left
  /// out unless [type] asks for one.
  Future<List<Airport>> getMapAirports({
    ({double south, double west, double north, double east})? bounds,
    String query = '',
    AirportType? type,
    bool usedOnly = false,
    bool customOnly = false,
    bool icaoOnly = false,
    Set<AirportType> excludedTypes = const {},
    required int limit,
  }) {
    final db = _database;
    final statement = db.select(db.airports)
      ..where((a) => a.latitudeDeg.isNotNull() & a.longitudeDeg.isNotNull())
      ..orderBy([
        // Large, medium, small, then the rest (seaplane bases ... closed).
        (a) => OrderingTerm.desc(
          a.type.isIn([
            AirportType.largeAirport.index,
            AirportType.mediumAirport.index,
            AirportType.smallAirport.index,
          ]),
        ),
        (a) => OrderingTerm.desc(a.type),
        (a) => OrderingTerm.asc(a.id),
      ])
      ..limit(limit);

    if (bounds != null) {
      // Served by airports_lat_lon_idx.
      statement.where(
        (a) =>
            a.latitudeDeg.isBetweenValues(bounds.south, bounds.north) &
            a.longitudeDeg.isBetweenValues(bounds.west, bounds.east),
      );
    }
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
    if (type != null) {
      statement.where((a) => a.type.equals(type.index));
    } else if (excludedTypes.isNotEmpty) {
      statement.where(_notOfTypes(excludedTypes));
    }
    if (customOnly) statement.where((a) => a.id.isSmallerThanValue(0));
    if (icaoOnly) statement.where(_icaoOrCustom);
    if (usedOnly) {
      final f = db.flights;
      statement.where(
        (a) =>
            a.id.isInQuery(db.selectOnly(f)..addColumns([f.departure])) |
            a.id.isInQuery(db.selectOnly(f)..addColumns([f.arrival])),
      );
    }
    return statement.get();
  }

  /// Stream of countries, by name.
  Stream<List<Country>> watchCountries() {
    return (_database.select(
      _database.countries,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  /// The airport with [id], or null.
  Future<Airport?> getAirport(int id) {
    return (_database.select(
      _database.airports,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// One-off search (no stream), e.g. for type-ahead lookups.
  Future<List<Airport>> findAirports(
    String query, {
    bool icaoOnly = false,
    Set<AirportType> excludedTypes = const {},
    int limit = 15,
  }) {
    return searchAirports(
      query: query,
      icaoOnly: icaoOnly,
      excludedTypes: excludedTypes,
      limit: limit,
    ).first;
  }

  /// Airports most recently used in flights, the most recent first.
  Future<List<Airport>> getRecentAirports({int limit = 5}) =>
      watchRecentAirports(limit: limit).first;

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

  /// How the airport is written in the exported logbook: [ident] in the
  /// PLACE columns instead of its own, whether to [annotate] it under the
  /// page (null: when it has no ICAO code) and the [note] to write there.
  /// Blank clears the texts.
  Future<void> setLogbookEntry(
    int id, {
    String? ident,
    bool? annotate,
    String? note,
  }) {
    String? orNull(String? text) =>
        text == null || text.trim().isEmpty ? null : text.trim();
    return (_database.update(
      _database.airports,
    )..where((a) => a.id.equals(id))).write(
      AirportsCompanion(
        logbookIdent: Value(orNull(ident)),
        logbookAnnotate: Value(annotate),
        logbookNote: Value(orNull(note)),
      ),
    );
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

  /// Whether a flight departed from or arrived at the airport.
  Future<bool> isAirportReferencedInFlights(int airportId) async {
    final used =
        await (_database.selectOnly(_database.flights)
              ..addColumns([_database.flights.id])
              ..where(
                _database.flights.departure.equals(airportId) |
                    _database.flights.arrival.equals(airportId),
              )
              ..limit(1))
            .getSingleOrNull();
    return used != null;
  }
}

final airportRepositoryProvider = Provider<AirportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AirportRepository(db);
});
