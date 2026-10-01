import 'dart:math';
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
  TextColumn get type => text()();
  TextColumn get model => text()();
  TextColumn get manufacturer => text()();
  TextColumn get tailNumber => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  List<TableIndex> get indexes => [
    TableIndex(name: 'aircrafts_created_at_idx', columns: {createdAt}),
  ];
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

  List<TableIndex> get indexes => [
    TableIndex(name: 'flights_departure_time_idx', columns: {departureTime}),
    TableIndex(name: 'flights_aircraft_id_idx', columns: {aircraftId}),
    TableIndex(name: 'flights_is_recording_idx', columns: {isRecording}),
    TableIndex(name: 'flights_departure_idx', columns: {departure}),
    TableIndex(name: 'flights_arrival_idx', columns: {arrival}),
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

/// Z is a fallback for aircrafts without wake category like sailplanes
enum WakeTurbolenceCategory { J, H, L, M, Z }

/// Z is a fallback for aircrafts without wake group like sailplanes
enum WakeTurbolenceGroup { A, B, C, D, E, F, G, Z }

enum EngineType { electric, jet, piston, rocket, turboprop, none }

enum AircraftDescription {
  amphibian,
  gyrocopter,
  helicopter,
  landplane,
  seaplane,
  tiltrotor,
  airship,
  balloon,
  glider,
  motorglider,
  microlightAutogyro,
  microlightHelicopter,
  paraplane,
  sailplane,
  ultralightAircraft,
  ultralightAutogyro,
  ultralightHelicopter,
  unsupported,
}

class IcaoAircrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get modelFullName => text()();
  TextColumn get wakeTurbolenceCategory =>
      textEnum<WakeTurbolenceCategory>().withLength(min: 1, max: 1)();
  TextColumn get wakeTurbolenceGroup =>
      textEnum<WakeTurbolenceGroup>().withLength(min: 1, max: 1)();
  TextColumn get manufacturer => text()();
  TextColumn get description => textEnum<AircraftDescription>()();
  IntColumn get engineCount => integer()();
  TextColumn get engineType => textEnum<EngineType>()();
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

class FlightWithStats {
  FlightWithStats({
    required this.flight,
    required this.dataPoints,
    this.aircraft,
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
  final Aircraft? aircraft;
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
    Aircraft? aircraft,
    Airport? departure,
    Airport? arrival,
    Duration? duration,
    int? maxAltitude,
    bool removeAircraft = false,
  }) => FlightWithStats(
    flight: flight ?? this.flight,
    dataPoints: dataPoints ?? this.dataPoints,
    aircraft: removeAircraft ? null : (aircraft ?? this.aircraft),
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

class AirportWithDistance {
  AirportWithDistance(this.airport, this.distance);
  final Airport airport;
  final double distance;
}

class AircraftWithStats extends Aircraft {
  AircraftWithStats({
    required Aircraft aircraft,
    required this.flightCount,
    this.totalFlightTime,
  }) : super(
         id: aircraft.id,
         type: aircraft.type,
         manufacturer: aircraft.manufacturer,
         createdAt: aircraft.createdAt,
         model: aircraft.model,
         notes: aircraft.notes,
         tailNumber: aircraft.tailNumber,
       );
  final int flightCount;
  final Duration? totalFlightTime;
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
  ],
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {},
  );

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

  Future<List<FlightWithStats>> getRecentFlights({int limit = 20}) async {
    final flightsQuery = select(flights)
      ..orderBy([(f) => OrderingTerm.desc(f.departureTime)])
      ..limit(limit);
    final recentFlights = await flightsQuery.get();

    if (recentFlights.isEmpty) return [];

    final flightIds = recentFlights.map((f) => f.id).toList();

    final dataPointsQuery = select(flightDataPoints)
      ..where((p) => p.flight.isIn(flightIds))
      ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]);
    final allPoints = await dataPointsQuery.get();

    final pointsByFlight = <int, List<FlightDataPoint>>{};
    for (final point in allPoints) {
      pointsByFlight.putIfAbsent(point.flight, () => []).add(point);
    }

    Future<Airport?> resolveAirport(int? id) async {
      if (id == null) return null;
      final query = select(airports)..where((a) => a.id.equals(id));
      final match = await query.getSingleOrNull();
      return match;
    }

    final aircraftCache = <int, Aircraft?>{};
    Future<Aircraft?> resolveAircraft(int? id) async {
      if (id == null) return null;
      if (aircraftCache.containsKey(id)) return aircraftCache[id];
      final query = select(aircrafts)..where((a) => a.id.equals(id));
      final match = await query.getSingleOrNull();
      aircraftCache[id] = match;
      return match;
    }

    final results = <FlightWithStats>[];
    for (final flight in recentFlights) {
      final points = pointsByFlight[flight.id] ?? const [];
      final departure = await resolveAirport(flight.departure);
      final arrival = await resolveAirport(flight.arrival);
      final aircraft = await resolveAircraft(flight.aircraftId);
      results.add(
        FlightWithStats(
          flight: flight,
          dataPoints: points,
          aircraft: aircraft,
          departure: departure,
          arrival: arrival,
        ),
      );
    }
    return results;
  }

  Future<List<Aircraft>> getAircrafts() async {
    return (select(
      aircrafts,
    )..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).get();
  }

  Future<Aircraft?> getAircraft(int id) async {
    final query = select(aircrafts)..where((a) => a.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<int> addAircraft({
    required String type,
    required String model,
    required String tailNumber,
    required String manufacturer,
    String? notes,
  }) async {
    return into(aircrafts).insert(
      AircraftsCompanion.insert(
        type: type,
        manufacturer: manufacturer,
        model: model,
        tailNumber: tailNumber,
        notes: Value(notes),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateAircraft(
    int id, {
    String? type,
    String? model,
    String? tailNumber,
    String? notes,
  }) async {
    await (update(aircrafts)..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        type: type != null ? Value(type) : const Value.absent(),
        model: model != null ? Value(model) : const Value.absent(),
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

  Future<void> deleteAircraft(int id) async {
    await (update(flights)..where((f) => f.aircraftId.equals(id))).write(
      const FlightsCompanion(aircraftId: Value(null)),
    );
    await (delete(aircrafts)..where((a) => a.id.equals(id))).go();
  }

  Future<List<AircraftWithStats>> getAircraftsWithStats() async {
    final allAircraft = await getAircrafts();
    final result = <AircraftWithStats>[];
    for (final ac in allAircraft) {
      final flightQuery = select(flights)
        ..where((f) => f.aircraftId.equals(ac.id))
        ..where((f) => f.isRecording.equals(false));
      final flightRows = await flightQuery.get();
      Duration? totalTime;
      for (final f in flightRows) {
        if (f.arrivalTime != null) {
          final dur = f.arrivalTime!.difference(f.departureTime);
          totalTime = (totalTime ?? Duration.zero) + dur;
        }
      }
      result.add(
        AircraftWithStats(
          aircraft: ac,
          flightCount: flightRows.length,
          totalFlightTime: totalTime,
        ),
      );
    }
    return result;
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

  Future<Map<int, bool>> areAirportsReferencedInFlights(
    List<int> airportIds,
  ) async {
    final result = <int, bool>{};
    for (final id in airportIds) {
      result[id] = await isAirportReferencedInFlights(id);
    }
    return result;
  }

  Future<List<FlightWithStats>> getFlightsForAircraft(
    int aircraftId, {
    int limit = 5,
    int offset = 0,
  }) async {
    final flightsQuery = select(flights)
      ..where((f) => f.aircraftId.equals(aircraftId))
      ..orderBy([(f) => OrderingTerm.desc(f.departureTime)])
      ..limit(limit, offset: offset);
    final flightRows = await flightsQuery.get();

    if (flightRows.isEmpty) return [];

    final flightIds = flightRows.map((f) => f.id).toList();

    final dataPointsQuery = select(flightDataPoints)
      ..where((p) => p.flight.isIn(flightIds))
      ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]);
    final allPoints = await dataPointsQuery.get();

    final pointsByFlight = <int, List<FlightDataPoint>>{};
    for (final point in allPoints) {
      pointsByFlight.putIfAbsent(point.flight, () => []).add(point);
    }
    Future<Airport?> resolveAirport(int? id) async {
      if (id == null) return null;
      final query = select(airports)..where((a) => a.id.equals(id));
      final match = await query.getSingleOrNull();
      return match;
    }

    final aircraft = await (select(
      aircrafts,
    )..where((a) => a.id.equals(aircraftId))).getSingleOrNull();

    final results = <FlightWithStats>[];
    for (final flight in flightRows) {
      final points = pointsByFlight[flight.id] ?? const [];
      final departure = await resolveAirport(flight.departure);
      final arrival = await resolveAirport(flight.arrival);
      results.add(
        FlightWithStats(
          flight: flight,
          dataPoints: points,
          aircraft: aircraft,
          departure: departure,
          arrival: arrival,
        ),
      );
    }
    return results;
  }
}
