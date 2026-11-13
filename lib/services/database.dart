// ignore_for_file: strict_raw_type

import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/aircraft_type_enums.dart';
import '../models/airport_type.dart';
import '../models/crew.dart';

export '../models/aircraft_type_enums.dart';
export '../models/airport_type.dart';
export '../models/crew.dart';

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

  List<TableIndex> get indexes => [
    TableIndex(name: 'airports_iso_country_idx', columns: {isoCountry}),
    TableIndex(
      name: 'airports_lat_lon_idx',
      columns: {latitudeDeg, longitudeDeg},
    ),
    TableIndex(name: 'airports_ident_idx', columns: {ident}),
    TableIndex(name: 'airports_icao_idx', columns: {icaoCode}),
    TableIndex(name: 'airports_iata_idx', columns: {iataCode}),
  ];
}

class Frequencies extends Table {
  IntColumn get id => integer()();

  @ReferenceName('frequencyRefs')
  IntColumn get airport => integer().references(Airports, #id)(); //airport_ref
  //IntColumn get airportIdent => integer().references(Airports, #ident)();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get frequencyMhz => text().withLength(min: 0, max: 8).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get indexes => [
    TableIndex(name: 'frequencies_airport_idx', columns: {airport}),
  ];
}

class Runways extends Table {
  IntColumn get id => integer()();

  @ReferenceName('runwayRefs')
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

  List<TableIndex> get indexes => [
    TableIndex(name: 'runways_airport_idx', columns: {airport}),
  ];
}

class Aircrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get icaoAircraft => integer().references(IcaoAircrafts, #id)();
  TextColumn get tailNumber => text()();
  TextColumn get notes => text().nullable()();
}

class Flights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  @ReferenceName("departureAirportRefs")
  IntColumn get departure => integer().nullable().references(Airports, #id)();
  @ReferenceName("arrivalAirportsRefs")
  IntColumn get arrival => integer().nullable().references(Airports, #id)();
  DateTimeColumn get departureTime => dateTime()();
  DateTimeColumn get arrivalTime => dateTime().nullable()();
  TextColumn get departureIanaLocation => text().nullable()();
  TextColumn get arrivalIanaLocation => text().nullable()();
  BoolColumn get isRecording => boolean()();
  IntColumn get aircraftId => integer().nullable().references(Aircrafts, #id)();
  TextColumn get approachType => text().nullable()();
  IntColumn get nightLandings => integer().nullable()();
  IntColumn get dayLandings => integer().nullable()();
  TextColumn get flightRules => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get pilotRole => text().nullable()();

  List<TableIndex> get indexes => [
    TableIndex(name: 'flights_departure_time_idx', columns: {departureTime}),
    TableIndex(name: 'flights_aircraft_id_idx', columns: {aircraftId}),
    TableIndex(name: 'flights_is_recording_idx', columns: {isRecording}),
    TableIndex(name: 'flights_departure_idx', columns: {departure}),
    TableIndex(name: 'flights_arrival_idx', columns: {arrival}),
  ];
}

@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get surname => text()();

  /// File name of the profile picture inside the app's people photo folder.
  TextColumn get photo => text().nullable()();
}

/// Many-to-many link between [Flights] and [People], with the role the
/// person had on that flight.
@DataClassName('FlightCrewEntry')
class FlightCrew extends Table {
  IntColumn get flight => integer().references(Flights, #id)();
  IntColumn get person => integer().references(People, #id)();
  TextColumn get role => textEnum<CrewRole>()();

  @override
  Set<Column<Object>>? get primaryKey => {flight, person};

  List<TableIndex> get indexes => [
    TableIndex(name: 'flight_crew_person_idx', columns: {person}),
  ];
}

class FlightDataPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get flight => integer().references(Flights, #id)();
  RealColumn get longitude => real()();
  RealColumn get latitude => real()();
  IntColumn get altitude => integer()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();

  List<TableIndex> get indexes => [
    TableIndex(
      name: 'flight_data_points_flight_timestamp_idx',
      columns: {flight, timestamp},
    ),
    TableIndex(name: 'flight_data_points_flight_idx', columns: {flight}),
    TableIndex(name: 'flight_data_points_timestamp_idx', columns: {timestamp}),
  ];
}

class IcaoAircrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get modelFullName => text()();
  TextColumn get designator => text()();
  TextColumn get wakeTurbolenceCategory =>
      textEnum<WakeTurbulenceCategory>().withLength(min: 1, max: 1)();
  TextColumn get wakeTurbolenceGroup =>
      textEnum<WakeTurbulenceGroup>().withLength(min: 1, max: 1)();
  TextColumn get manufacturer => text()();
  TextColumn get description => textEnum<AircraftDescription>()();
  IntColumn get engineCount => integer()();
  TextColumn get engineType => textEnum<EngineType>()();
  BoolColumn get userInserted => boolean().withDefault(const Constant(false))();
}

class AirportWithEverything {
  AirportWithEverything({
    required this.airport,
    required this.country,
    required this.region,
    required this.runways,
    required this.frequencies,
  });
  final Airport airport;
  final List<Frequency> frequencies;
  final List<Runway> runways;
  final Country country;
  final Region region;
}

class FlightWithStats {
  FlightWithStats({
    required this.flight,
    required this.dataPoints,
    this.aircraftWithStats,
    this.departure,
    this.arrival,
  }) {
    duration = flight.arrivalTime?.difference(flight.departureTime);
    maxAltitude = dataPoints.isEmpty
        ? null
        : dataPoints.map((p) => p.altitude).reduce((a, b) => a > b ? a : b);
  }
  final Flight flight;
  final List<FlightDataPoint> dataPoints;
  final AircraftWithStats? aircraftWithStats;
  final Airport? departure;
  final Airport? arrival;
  Duration? duration;
  int? maxAltitude;

  double? get totalDistance {
    if (dataPoints.length < 2) return null;
    double dist = 0;
    for (int i = 1; i < dataPoints.length; i++) {
      dist += _haversine(
        dataPoints[i - 1].latitude,
        dataPoints[i - 1].longitude,
        dataPoints[i].latitude,
        dataPoints[i].longitude,
      );
    }
    return dist;
  }

  FlightWithStats copyWith({
    Flight? flight,
    List<FlightDataPoint>? dataPoints,
    AircraftWithStats? aircraftWithStats,
    Airport? departure,
    Airport? arrival,
    Duration? duration,
    int? maxAltitude,
    bool removeAircraft = false,
  }) => FlightWithStats(
    flight: flight ?? this.flight,
    dataPoints: dataPoints ?? this.dataPoints,
    aircraftWithStats: removeAircraft
        ? null
        : (aircraftWithStats ?? this.aircraftWithStats),
    departure: departure ?? this.departure,
    arrival: arrival ?? this.arrival,
  );

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  static double _toRadians(double deg) => deg * 3.141592653589793 / 180;
}

/// A person on a flight together with their role.
class CrewMember {
  const CrewMember({required this.person, required this.role});
  final Person person;
  final CrewRole role;
}

/// A person plus when they last flew with the user (null if never).
class PersonWithLastFlight {
  const PersonWithLastFlight({
    required this.person,
    this.lastFlight,
    this.flightCount = 0,
  });
  final Person person;
  final DateTime? lastFlight;
  final int flightCount;
}

extension PersonFullName on Person {
  String get fullName => '$name $surname'.trim();
}

class AirportWithDistance {
  AirportWithDistance(this.airport, this.distance);
  final Airport airport;
  final double distance;
}

abstract class FlightStats extends View {
  Flights get flights;
  Expression<int> get flightTime => CustomExpression<int>('''
      CAST(
        (
          ${flights.arrivalTime.escapedNameFor(SqlDialect.sqlite)} -
          ${flights.departureTime.escapedNameFor(SqlDialect.sqlite)}
        ) / 60
        AS INTEGER
      )
    ''');

  @override
  Query as() => select([
    flights.id,
    flights.aircraftId,
    flightTime,
    flights.dayLandings,
    flights.nightLandings,
  ]).from(flights);
}

@DataClassName("AircraftWithStats")
abstract class AircraftWithStatss extends View {
  Aircrafts get aircrafts;
  Flights get flights;
  IcaoAircrafts get icaoAircrafts;

  Expression<int> get flightCount => flights.id.count();
  Expression<int> get dayLandings => flights.dayLandings.sum();
  Expression<int> get nightLandings => flights.nightLandings.sum();
  Expression<int> get totalFlightTime => CustomExpression<int>('''
    SUM(
      CAST(
        (
          ${flights.arrivalTime.escapedNameFor(SqlDialect.sqlite)} -
          ${flights.departureTime.escapedNameFor(SqlDialect.sqlite)}
        ) / 60
        AS INTEGER
      )
    )
    ''');

  @override
  Query as() =>
      select([
          aircrafts.id,
          aircrafts.tailNumber,
          aircrafts.notes,
          aircrafts.icaoAircraft,
          icaoAircrafts.description,
          icaoAircrafts.modelFullName,
          icaoAircrafts.designator,
          icaoAircrafts.manufacturer,
          icaoAircrafts.engineCount,
          icaoAircrafts.engineType,
          icaoAircrafts.wakeTurbolenceCategory,
          icaoAircrafts.wakeTurbolenceGroup,
          icaoAircrafts.userInserted,
          dayLandings,
          nightLandings,
          flightCount,
          totalFlightTime,
        ]).from(aircrafts).join([
          leftOuterJoin(flights, flights.aircraftId.equalsExp(aircrafts.id)),
          innerJoin(
            icaoAircrafts,
            aircrafts.icaoAircraft.equalsExp(icaoAircrafts.id),
          ),
        ])
        ..groupBy([aircrafts.id]);
}

@DataClassName("AircraftWithIcao")
abstract class AircraftWithIcaos extends View {
  Aircrafts get aircrafts;
  IcaoAircrafts get icaoAircrafts;

  @override
  Query as() =>
      select([
          aircrafts.id,
          aircrafts.tailNumber,
          aircrafts.notes,
          aircrafts.icaoAircraft,
          icaoAircrafts.description,
          icaoAircrafts.modelFullName,
          icaoAircrafts.designator,
          icaoAircrafts.manufacturer,
          icaoAircrafts.engineCount,
          icaoAircrafts.engineType,
          icaoAircrafts.wakeTurbolenceCategory,
          icaoAircrafts.wakeTurbolenceGroup,
          icaoAircrafts.userInserted,
        ]).from(aircrafts).join([
          innerJoin(
            icaoAircrafts,
            aircrafts.icaoAircraft.equalsExp(icaoAircrafts.id),
          ),
        ])
        ..groupBy([aircrafts.id]);
}

extension ToIcaoAircraft on AircraftWithStats {
  IcaoAircraft toIcaoAircraft() {
    return IcaoAircraft(
      id: id,
      modelFullName: modelFullName,
      designator: designator,
      wakeTurbolenceCategory: wakeTurbolenceCategory,
      wakeTurbolenceGroup: wakeTurbolenceGroup,
      manufacturer: manufacturer,
      description: description,
      engineCount: engineCount,
      engineType: engineType,
      userInserted: userInserted,
    );
  }
}

@DriftDatabase(
  tables: [
    Countries,
    Regions,
    Airports,
    Frequencies,
    Runways,
    Flights,
    FlightDataPoints,
    Aircrafts,
    IcaoAircrafts,
    People,
    FlightCrew,
  ],
  views: [AircraftWithStatss, FlightStats, AircraftWithIcaos],
)
class LogbookDatabase extends _$LogbookDatabase {
  factory LogbookDatabase([QueryExecutor? executor]) {
    if (executor != null) {
      return LogbookDatabase._(executor);
    }
    _instance ??= LogbookDatabase._(_openConnection());
    return _instance!;
  }

  LogbookDatabase._(super.executor);
  static LogbookDatabase? _instance;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement('ALTER TABLE flights ADD COLUMN pilot_role TEXT');
        await customStatement('ALTER TABLE flights ADD COLUMN crew_json TEXT');
      }
      if (from < 3) {
        await m.createTable(people);
        await m.createTable(flightCrew);
        await m.createIndex(
          Index(
            'flight_crew_person_idx',
            'CREATE INDEX IF NOT EXISTS flight_crew_person_idx '
                'ON flight_crew (person)',
          ),
        );
        await _migrateCrewJson();
        // Rebuild flights without the crew_json column.
        await m.alterTable(TableMigration(flights));
      }
      // Databases upgraded from < 3 got `people` with this column already.
      if (from == 3) {
        await m.addColumn(people, people.photo);
      }
    },
  );

  /// Moves the legacy `flights.crew_json` column into [people] and
  /// [flightCrew]. Names are split on the first space into name / surname.
  Future<void> _migrateCrewJson() async {
    final rows = await customSelect(
      'SELECT id, crew_json FROM flights WHERE crew_json IS NOT NULL',
    ).get();
    final personIds = <String, int>{};
    for (final row in rows) {
      final flightId = row.read<int>('id');
      final List<dynamic> members;
      try {
        members = jsonDecode(row.read<String>('crew_json')) as List<dynamic>;
      } catch (_) {
        continue;
      }
      for (final m in members.whereType<Map<String, dynamic>>()) {
        final fullName = (m['name'] as String? ?? '').trim();
        if (fullName.isEmpty) continue;
        final space = fullName.indexOf(' ');
        final name = space < 0 ? fullName : fullName.substring(0, space);
        final surname = space < 0 ? '' : fullName.substring(space + 1).trim();
        final key = fullName.toLowerCase();
        final personId = personIds[key] ??= await into(
          people,
        ).insert(PeopleCompanion.insert(name: name, surname: surname));
        await into(flightCrew).insert(
          FlightCrewCompanion.insert(
            flight: flightId,
            person: personId,
            role: CrewRole.fromString(m['role'] as String? ?? 'oth'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'zenith',
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

  Future<List<Airport>> searchAirports({
    String query = '',
    String? countryCode,
    AirportType? type,
    int limit = 100,
  }) async {
    final statement = select(airports)..limit(limit);

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

    return statement.get();
  }

  Future<List<Airport>> getAllAirportsAlphabetical({int limit = 100}) async {
    return (select(airports)
          ..orderBy([(a) => OrderingTerm.asc(a.name)])
          ..limit(limit))
        .get();
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

  Future<List<Aircraft>> getAircrafts() async {
    return (select(aircrafts)..orderBy([(a) => OrderingTerm.desc(a.id)])).get();
  }

  Future<Aircraft?> getAircraft(int id) async {
    final query = select(aircrafts)..where((a) => a.id.equals(id));
    return query.getSingleOrNull();
  }

  /// Get all ICAO aircrafts (for dropdown)
  Future<List<IcaoAircraft>> getAllIcaoAircrafts({int limit = 200}) async {
    return (select(icaoAircrafts)
          ..orderBy([(a) => OrderingTerm.asc(a.modelFullName)])
          ..limit(limit))
        .get();
  }

  /// Add a new ICAO aircraft (user inserted)
  Future<int> addIcaoAircraft({
    required String modelFullName,
    required String manufacturer,
    required String designator,
    required WakeTurbulenceCategory wakeTurbolenceCategory,
    required WakeTurbulenceGroup wakeTurbolenceGroup,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) async {
    return into(icaoAircrafts).insert(
      IcaoAircraftsCompanion.insert(
        modelFullName: modelFullName,
        designator: designator,
        manufacturer: manufacturer,
        wakeTurbolenceCategory: wakeTurbolenceCategory,
        wakeTurbolenceGroup: wakeTurbolenceGroup,
        description: description,
        engineCount: engineCount,
        engineType: engineType,
        userInserted: const Value(true),
      ),
    );
  }

  Future<int> addAircraft({
    required int icaoAircraftId,
    required String tailNumber,
    String? notes,
  }) async {
    return into(aircrafts).insert(
      AircraftsCompanion.insert(
        icaoAircraft: icaoAircraftId,
        tailNumber: tailNumber,
        notes: Value(notes),
      ),
    );
  }

  Future<void> updateAircraft(
    int id, {
    int? icaoAircraftId,
    String? tailNumber,
    String? notes,
  }) async {
    await (update(aircrafts)..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        icaoAircraft: icaoAircraftId != null
            ? Value(icaoAircraftId)
            : const Value.absent(),
        tailNumber: tailNumber != null
            ? Value(tailNumber)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
      ),
    );
  }

  Future<void> updateFlightAircraft(int flightId, {int? aircraftId}) async {
    await (update(flights)..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(aircraftId: Value(aircraftId)),
    );
  }

  /// Crew of a flight (excluding self), in insertion order.
  Future<List<CrewMember>> getFlightCrew(int flightId) =>
      _flightCrewQuery(flightId).get().then(_toCrew);

  /// Live crew of a flight (excluding self).
  Stream<List<CrewMember>> watchFlightCrew(int flightId) =>
      _flightCrewQuery(flightId).watch().map(_toCrew);

  JoinedSelectStatement<HasResultSet, dynamic> _flightCrewQuery(int flightId) {
    return select(flightCrew).join([
      innerJoin(people, people.id.equalsExp(flightCrew.person)),
    ])..where(flightCrew.flight.equals(flightId));
  }

  List<CrewMember> _toCrew(List<TypedResult> rows) => [
    for (final row in rows)
      CrewMember(
        person: row.readTable(people),
        role: row.readTable(flightCrew).role,
      ),
  ];

  /// Crew of many flights at once, keyed by flight id (flights without crew
  /// are absent from the map).
  Future<Map<int, List<CrewMember>>> getCrewForFlights(
    Iterable<int> flightIds,
  ) async {
    final rows = await (select(flightCrew).join([
      innerJoin(people, people.id.equalsExp(flightCrew.person)),
    ])..where(flightCrew.flight.isIn(flightIds))).get();
    final result = <int, List<CrewMember>>{};
    for (final row in rows) {
      final entry = row.readTable(flightCrew);
      (result[entry.flight] ??= []).add(
        CrewMember(person: row.readTable(people), role: entry.role),
      );
    }
    return result;
  }

  /// Replaces the whole crew of [flightId] with [crew].
  Future<void> setFlightCrew(int flightId, List<CrewMember> crew) {
    return transaction(() async {
      await (delete(flightCrew)..where((c) => c.flight.equals(flightId))).go();
      await batch((b) {
        b.insertAll(flightCrew, [
          for (final member in crew)
            FlightCrewCompanion.insert(
              flight: flightId,
              person: member.person.id,
              role: member.role,
            ),
        ], mode: InsertMode.insertOrReplace);
      });
    });
  }

  Future<void> deleteAircraft(int id) async {
    await (update(flights)..where((f) => f.aircraftId.equals(id))).write(
      const FlightsCompanion(aircraftId: Value(null)),
    );
    await (delete(aircrafts)..where((a) => a.id.equals(id))).go();
  }

  Future<List<Airport>> getRecentAirports({int limit = 5}) async {
    final recentFlightsQuery = select(flights)
      ..orderBy([(f) => OrderingTerm.desc(f.departureTime)])
      ..limit(20);
    final recentFlights = await recentFlightsQuery.get();
    final airportIds = <int>{};
    for (final f in recentFlights) {
      if (f.departure != null) airportIds.add(f.departure!);
      if (f.arrival != null) airportIds.add(f.arrival!);
    }
    if (airportIds.isEmpty) return [];
    final airportQuery = select(airports)
      ..where((a) => a.id.isIn(airportIds.toList()))
      ..limit(limit);
    return airportQuery.get();
  }

  Future<bool> isAirportReferencedInFlights(int airportId) async {
    final departureCountQuery = select(flights)
      ..where((f) => f.departure.equals(airportId));
    final arrivalCountQuery = select(flights)
      ..where((f) => f.arrival.equals(airportId));

    final departureCount = await departureCountQuery.get();
    if (departureCount.isNotEmpty) return true;

    final arrivalCount = await arrivalCountQuery.get();
    return arrivalCount.isNotEmpty;
  }

  /// Ids of every airport used as departure or arrival by any flight.
  Future<Set<int>> getReferencedAirportIds() async {
    final rows = await customSelect(
      'SELECT departure AS id FROM flights WHERE departure IS NOT NULL '
      'UNION SELECT arrival AS id FROM flights WHERE arrival IS NOT NULL',
      readsFrom: {flights},
    ).get();
    return {for (final row in rows) row.read<int>('id')};
  }
}
