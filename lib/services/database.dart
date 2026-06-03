import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Countries extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text().withLength(min: 2, max: 2).unique()();
  TextColumn get name => text()();
  TextColumn get continent => text().withLength(min: 2, max: 2)();
  TextColumn get wikipediaLink => text().nullable()();
  TextColumn get keywords => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Regions extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text().withLength(min: 2, max: 10).unique()();
  TextColumn get localCode => text().withLength(min: 0, max: 20).nullable()();
  TextColumn get name => text()();
  TextColumn get continent => text().withLength(min: 2, max: 2)();
  TextColumn get isoCountry =>
      text().withLength(min: 2, max: 2).references(Countries, #code)();
  TextColumn get wikipediaLink => text().nullable()();
  TextColumn get keywords => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

enum AirportType {
  undefined,
  closed,
  smallAirport,
  mediumAirport,
  largeAirport,
  heliport,
  balloonport,
  seaplaneBase;

  static AirportType fromCsvString(String str) {
    switch (str) {
      case "small_airport":
        return AirportType.smallAirport;
      case "medium_airport":
        return AirportType.mediumAirport;
      case "large_airport":
        return AirportType.largeAirport;
      case "balloonport":
        return AirportType.balloonport;
      case "heliport":
        return AirportType.heliport;
      case "seaplane_base":
        return AirportType.seaplaneBase;
      case "closed":
        return AirportType.closed;
      default:
        return AirportType.undefined;
    }
  }

  static String getDisplayName(AirportType type) {
    switch (type) {
      case AirportType.smallAirport:
        return "Small Airport";
      case AirportType.mediumAirport:
        return "Medium Airport";
      case AirportType.largeAirport:
        return "Large Airport";
      case AirportType.balloonport:
        return "Balloonport";
      case AirportType.heliport:
        return "Heliport";
      case AirportType.seaplaneBase:
        return "Seaplane Base";
      case AirportType.closed:
        return "Closed";
      case AirportType.undefined:
        return "Undefined";
    }
  }
}

class Airports extends Table {
  IntColumn get id => integer()();
  TextColumn get ident => text().unique().nullable()();
  IntColumn get type => intEnum<AirportType>()();
  TextColumn get name => text().nullable()();
  RealColumn get latitudeDeg => real().nullable()();
  RealColumn get longitudeDeg => real().nullable()();
  IntColumn get elevationFt => integer().nullable()();
  TextColumn get continent => text().withLength(min: 2, max: 2)();
  TextColumn get isoCountry =>
      text().withLength(min: 2, max: 2).references(Countries, #code)();
  TextColumn get isoRegion =>
      text().withLength(min: 2, max: 10).references(Regions, #code)();
  TextColumn get municipality => text().nullable()();
  BoolColumn get scheduledService => boolean().nullable()();
  TextColumn get icaoCode => text().nullable()();
  TextColumn get iataCode => text().nullable()();
  TextColumn get gpsCode => text().nullable()();
  TextColumn get localCode => text().nullable()();
  TextColumn get homeLink => text().nullable()();
  TextColumn get wikipediaLink => text().nullable()();
  TextColumn get keywords => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Frequencies extends Table {
  IntColumn get id => integer()();
  IntColumn get airport => integer().references(Airports, #id)(); //airport_ref
  //IntColumn get airportIdent => integer().references(Airports, #ident)();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get frequencyMhz => text().withLength(min: 0, max: 8).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Runways extends Table {
  IntColumn get id => integer()();
  IntColumn get airport => integer().references(Airports, #id)(); //airport_ref
  //IntColumn get airportIdent => integer().references(Airports, #ident)();
  IntColumn get lengthFt => integer().nullable()();
  IntColumn get widthFt => integer().nullable()();
  TextColumn get surface => text().nullable()();
  BoolColumn get lighted => boolean().nullable()();
  BoolColumn get closed => boolean().nullable()();

  // Low-Elevation (LE) Runway End Data
  TextColumn get leIdent => text().nullable()();
  RealColumn get leLatitudeDeg => real().nullable()();
  RealColumn get leLongitudeDeg => real().nullable()();
  IntColumn get leElevationFt => integer().nullable()();
  RealColumn get leHeadingDegT => real().nullable()();
  IntColumn get leDisplacedThresholdFt => integer().nullable()();

  // High-Elevation (HE) Runway End Data
  TextColumn get heIdent => text().nullable()();
  RealColumn get heLatitudeDeg => real().nullable()();
  RealColumn get heLongitudeDeg => real().nullable()();
  IntColumn get heElevationFt => integer().nullable()();
  RealColumn get heHeadingDegT => real().nullable()();
  IntColumn get heDisplacedThresholdFt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AirportWithEverything {
  AirportWithEverything({
    required this.airport,
    required this.country,
    required this.region,
    this.runways,
    this.frequencies,
  });
  final Airport airport;
  final List<Frequency>? frequencies;
  final List<Runway>? runways;
  final Country country;
  final Region region;
}

class AirportWithDistance {
  final Airport airport;
  final double distance;
  AirportWithDistance(this.airport, this.distance);
}

@DriftDatabase(tables: [Countries, Regions, Airports, Frequencies, Runways])
class LogbookDatabase extends _$LogbookDatabase {
  LogbookDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'logbook',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<AirportWithEverything?> getCompleteAirportData(int airportId) async {
    final query = select(airports).join([
      leftOuterJoin(countries, countries.code.equalsExp(airports.isoCountry)),
      leftOuterJoin(regions, regions.code.equalsExp(airports.isoRegion)),
    ])..where(airports.id.equals(airportId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final airport = row.readTable(airports);
    final country = row.readTable(countries);
    final region = row.readTable(regions);

    final runwaysQuery = select(this.runways)
      ..where((r) => r.airport.equals(airportId));
    final runways = await runwaysQuery.get();

    final frequenciesQuery = select(this.frequencies)
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

  Future<List<Airport>?> getAirportsWithinSquare(
    double latitude,
    double longitude, {
    double delta = 2.0,
  }) {
    final query = select(airports)
      ..where(
        (a) =>
            a.latitudeDeg.isBetweenValues(latitude - delta, latitude + delta),
      )
      ..where(
        (a) => a.longitudeDeg.isBetweenValues(
          longitude - delta,
          longitude + delta,
        ),
      );

    return query.get();
  }
}
