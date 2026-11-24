// ignore_for_file: strict_raw_type

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/aircraft_class.dart';
import '../models/aircraft_photo.dart';
import '../models/aircraft_type_enums.dart';
import '../models/airport_type.dart';
import '../models/crew.dart';
import '../models/flight_track.dart';
import '../models/licence.dart';
import '../models/logbook_overrides.dart';
import '../models/previous_totals.dart';
import '../models/simulator_kind.dart';
import '../utils/night_time.dart';

export '../models/aircraft_class.dart';
export '../models/aircraft_photo.dart';
export '../models/aircraft_type_enums.dart';
export '../models/airport_type.dart';
export '../models/crew.dart';
export '../models/licence.dart';
export '../models/logbook_overrides.dart';
export '../models/previous_totals.dart';
export '../models/simulator_kind.dart';

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

@TableIndex(
  name: 'airports_lat_lon_idx',
  columns: {#latitudeDeg, #longitudeDeg},
)
@TableIndex(name: 'airports_iso_country_idx', columns: {#isoCountry})
@TableIndex(name: 'airports_icao_idx', columns: {#icaoCode})
@TableIndex(name: 'airports_iata_idx', columns: {#iataCode})
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

  /// The pilot's own ident for the PLACE columns of the exported logbook.
  /// Null: the airport's ident. Kept by the airport data sync.
  TextColumn get logbookIdent => text().nullable()();

  /// Whether pages using the airport describe it under the table. Null: only
  /// when it has no ICAO code (see [AirportLogbook.needsLogbookNote]).
  BoolColumn get logbookAnnotate => boolean().nullable()();

  /// The pilot's own description under the table. Null: worked out from the
  /// airport's data.
  TextColumn get logbookNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'frequencies_airport_idx', columns: {#airport})
class Frequencies extends Table {
  IntColumn get id => integer()();

  @ReferenceName('frequencyRefs')
  IntColumn get airport => integer().references(Airports, #id)();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get frequencyMhz => text().withLength(min: 0, max: 8).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'runways_airport_idx', columns: {#airport})
class Runways extends Table {
  IntColumn get id => integer()();

  @ReferenceName('runwayRefs')
  IntColumn get airport => integer().references(Airports, #id)();
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

class Aircrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get icaoAircraft => integer().references(IcaoAircrafts, #id)();
  TextColumn get tailNumber => text()();
  TextColumn get notes => text().nullable()();

  /// Rating the aircraft is flown under. Null until it is chosen.
  TextColumn get aircraftClass => textEnum<AircraftClass>().nullable()();

  /// Licence endorsement of the type rating (e.g. "A320"), when
  /// [aircraftClass] is [AircraftClass.type].
  TextColumn get typeRating => text().nullable()();

  /// File name of a photo the user picked themselves, inside the app's
  /// aircraft photo folder. Shown instead of the online photo.
  TextColumn get photoFile => text().nullable()();

  /// Photo found online (JetPhotos). The picture is never stored, only where
  /// it is: full size image, small image for lists, the page it comes from
  /// and who took it.
  TextColumn get photoUrl => text().nullable()();
  TextColumn get photoThumbnailUrl => text().nullable()();
  TextColumn get photoLink => text().nullable()();
  TextColumn get photoCredit => text().nullable()();

  /// How the aircraft is written in column 4 of the exported logbook,
  /// instead of its ICAO type designator: e.g. "B747" for a "B744".
  TextColumn get logbookType => text().nullable()();

  /// A second line under the type in the exported logbook, for the model or
  /// variant ("747-400F"). None by default.
  TextColumn get logbookSubtitle => text().nullable()();
}

/// A flight simulation training device the user flies sessions in. A
/// session is a [Flights] row pointing at it through [Flights.simulatorId].
class Simulators extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<SimulatorKind>()();

  /// Qualification level ("D" for an FFS, "II MCC" for an FNPT). Null when
  /// not known or the kind has none.
  TextColumn get level => text().nullable()();

  /// The aircraft type the device represents. Null for a generic device
  /// (an FNPT representing a class, a BITD).
  IntColumn get icaoAircraft =>
      integer().nullable().references(IcaoAircrafts, #id)();

  /// Class or type rating sessions in the device count towards (FFS
  /// landings, proficiency checks).
  TextColumn get aircraftClass => textEnum<AircraftClass>().nullable()();

  /// Licence endorsement of the type rating (e.g. "A320"), when
  /// [aircraftClass] is [AircraftClass.type].
  TextColumn get typeRating => text().nullable()();

  /// The device's qualification number ("Q1234"), written next to its type
  /// in the logbook.
  TextColumn get qualificationNumber => text().nullable()();

  /// Training organisation or operator running it, and where.
  TextColumn get organisation => text().nullable()();
  TextColumn get notes => text().nullable()();
}

@TableIndex(name: 'flights_simulator_id_idx', columns: {#simulatorId})
@TableIndex(name: 'flights_departure_time_idx', columns: {#departureTime})
@TableIndex(name: 'flights_aircraft_id_idx', columns: {#aircraftId})
@TableIndex(name: 'flights_departure_idx', columns: {#departure})
@TableIndex(name: 'flights_arrival_idx', columns: {#arrival})
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

  /// Set for a flight recorded by the app that hasn't been completed in the
  /// flight form yet: it isn't in the logbook. Without an [arrivalTime] it is
  /// still being recorded; with one, it is a temporary flight.
  BoolColumn get isRecording => boolean()();
  IntColumn get aircraftId => integer().nullable().references(Aircrafts, #id)();

  /// Set for a session in a flight simulation training device instead of a
  /// flight: it then has no aircraft, airports, flight rules or track, and
  /// fills in the FSTD column of the logbook only.
  IntColumn get simulatorId =>
      integer().nullable().references(Simulators, #id)();
  TextColumn get approachType => text().nullable()();
  IntColumn get nightLandings => integer().nullable()();
  IntColumn get dayLandings => integer().nullable()();

  /// How many of the landings were on a surface designated to require a
  /// mountain rating: what keeps its privileges (FCL.815(d)(1)). Null when
  /// none.
  IntColumn get mountainLandings => integer().nullable()();
  TextColumn get flightRules => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get pilotRole => text().nullable()();

  /// Time flown under instrument flight rules, in minutes: none for a VFR
  /// flight, all of it for an IFR one, what the pilot entered for one that
  /// changes rules on the way. Null when not known.
  IntColumn get instrumentMinutes => integer().nullable()();

  /// Time flown at night, in minutes, worked out from the airports and times
  /// (see [NightTime]). Null when it can't be: an airport without a position,
  /// no arrival time.
  IntColumn get nightMinutes => integer().nullable()();

  /// Logbook values the pilot entered by hand, replacing the computed ones
  /// in the exported logbook.
  TextColumn get logbookOverrides =>
      text().map(LogbookOverrides.converter).nullable()();

  /// Where the track in [FlightDataPoints] comes from: the id of the ADS-B
  /// provider it was fetched from (`AdsbTrackSource.id`). Null for a track
  /// the app recorded itself, and for flights without a track.
  TextColumn get trackSource => text().nullable()();

  /// Whether the flight was a proficiency check with an examiner in the
  /// crew: it then counts as the last check of the class or type rating of
  /// its aircraft.
  BoolColumn get proficiencyCheck =>
      boolean().withDefault(const Constant(false))();

  /// File name of the signature (or photo of the paper logbook's remarks)
  /// inside the app's signature folder, laid over the remarks in the
  /// exported logbook.
  TextColumn get signatureFile => text().nullable()();
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
@TableIndex(name: 'flight_crew_person_idx', columns: {#person})
class FlightCrew extends Table {
  IntColumn get flight => integer().references(Flights, #id)();
  IntColumn get person => integer().references(People, #id)();
  TextColumn get role => textEnum<CrewRole>()();

  @override
  Set<Column<Object>>? get primaryKey => {flight, person};
}

/// The track of a flight, one row per position: recorded by the app's GPS,
/// or fetched from an ADS-B provider (see [Flights.trackSource]).
///
/// A track is always read whole and in order, so the one index is on
/// (flight, timestamp): it finds a flight's rows without scanning the
/// table, already sorted.
@TableIndex(
  name: 'flight_data_points_flight_timestamp_idx',
  columns: {#flight, #timestamp},
)
class FlightDataPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get flight => integer().references(Flights, #id)();
  RealColumn get longitude => real()();
  RealColumn get latitude => real()();

  /// Metres.
  IntColumn get altitude => integer()();
  DateTimeColumn get timestamp => dateTime()();

  /// Ground speed, km/h.
  RealColumn get speed => real().nullable()();

  /// Degrees.
  RealColumn get heading => real().nullable()();
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

/// A pilot licence held by the user.
class Licences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<LicenceKind>()();
  TextColumn get category => textEnum<AircraftCategory>()();

  /// Licence number, as printed on it.
  TextColumn get number => text().nullable()();

  /// Who issued it: the competent authority ("ENAC", "LBA"...).
  TextColumn get issuedBy => text().nullable()();
  DateTimeColumn get issueDate => dateTime().nullable()();

  /// Last proficiency check with an examiner, which keeps a LAPL(A) recent
  /// for 2 years on its own (FCL.140.A(a)(2)).
  DateTimeColumn get proficiencyCheckDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

/// A rating, endorsement or certificate on a [Licences] row.
@DataClassName('LicenceRating')
@TableIndex(name: 'licence_ratings_licence_idx', columns: {#licence})
class LicenceRatings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get licence => integer().references(Licences, #id)();
  TextColumn get kind => textEnum<RatingKind>()();

  /// The class, for a [RatingKind.classRating].
  TextColumn get aircraftClass => textEnum<AircraftClass>().nullable()();

  /// What the pilot calls it: the type rating endorsement ("A320"), the
  /// instructor certificate ("FI(A)"), the language...
  TextColumn get name => text().nullable()();

  /// Language proficiency level (4 to 6).
  IntColumn get level => integer().nullable()();
  DateTimeColumn get issueDate => dateTime().nullable()();

  /// Last proficiency check (or skill test, assessment of competence).
  DateTimeColumn get lastCheckDate => dateTime().nullable()();

  /// Last day of validity, as endorsed on the licence. Null when it doesn't
  /// expire.
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  /// For a helicopter type rating: whether the type is a single-engine
  /// helicopter with a maximum take-off mass up to 3 175 kg, which may be
  /// revalidated with 6 hours as PIC and a refresher training instead of a
  /// proficiency check (FCL.740.H(a)(2)).
  BoolColumn get lightSingleEngine =>
      boolean().withDefault(const Constant(false))();
}

/// A medical certificate (Part-MED).
@DataClassName('MedicalCertificate')
class MedicalCertificates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get medicalClass => textEnum<MedicalClass>()();
  DateTimeColumn get examinationDate => dateTime().nullable()();

  /// Last day of validity, as written on the certificate.
  DateTimeColumn get expiryDate => dateTime()();

  /// Limitations on the certificate (VML, SSL...).
  TextColumn get limitations => text().nullable()();
  TextColumn get notes => text().nullable()();
}

/// The pilot's own data that belongs with the logbook, and so travels in
/// backups. A single row, with id [PilotProfile.rowId].
@DataClassName('PilotProfileRow')
class PilotProfile extends Table {
  static const rowId = 1;

  IntColumn get id => integer()();

  /// Totals logged before the app, carried forward into the logbook.
  TextColumn get previousTotals =>
      text().map(PreviousTotals.converter).nullable()();

  /// File name of the pilot's signature inside the app's signature folder,
  /// put in the "pilot's signature" box of each page of the exported
  /// logbook.
  TextColumn get signatureFile => text().nullable()();

  /// The pilot's postal address, part of the personal details a logbook
  /// records (AMC1 FCL.050(a)(1)). Several lines.
  TextColumn get address => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The night time of a flight from [departure] to [arrival] (see
/// [NightTime]), or null when it can't be worked out: no arrival time, or
/// neither a [track] nor airports with a position.
///
/// The [track] (recorded or from ADS-B) is the route when there is one, with
/// the airports at either end for the time it doesn't cover (taxiing, or
/// before the aircraft was first seen). Without one, the route is the great
/// circle between the airports.
Duration? nightTimeOf({
  required DateTime departureTime,
  required DateTime? arrivalTime,
  required Airport? departure,
  required Airport? arrival,
  Iterable<TimedPosition> track = const [],
}) {
  if (arrivalTime == null) return null;
  TimedPosition? at(Airport? a, DateTime time) {
    final lat = a?.latitudeDeg;
    final lon = a?.longitudeDeg;
    return lat == null || lon == null
        ? null
        : (time: time, latitude: lat, longitude: lon);
  }

  final from = at(departure, departureTime);
  final to = at(arrival, arrivalTime);
  final flown =
      track
          .where(
            (p) =>
                !p.time.isBefore(departureTime) && !p.time.isAfter(arrivalTime),
          )
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
  if (flown.isEmpty && (from == null || to == null)) return null;
  return NightTime.along(
    [?from, ...flown, ?to],
    departure: departureTime,
    arrival: arrivalTime,
  );
}

extension FlightDataPointPosition on FlightDataPoint {
  TimedPosition get timedPosition =>
      (time: timestamp, latitude: latitude, longitude: longitude);
}

/// Airports the user added themselves have negative ids: OurAirports ids are
/// positive, so the two can never collide and the sync leaves these alone.
extension CustomAirport on Airport {
  bool get isCustom => id < 0;
}

/// AMC1 FCL.050(i)(3): places are ICAO identifiers. Anything else gets
/// described under the logbook page.
extension AirportLogbook on Airport {
  bool get needsLogbookNote => isCustom || (icaoCode?.trim().isEmpty ?? true);

  /// What the PLACE columns of the exported logbook say: the pilot's
  /// override, or the airport's ident.
  String get logbookPlace {
    final custom = logbookIdent?.trim() ?? '';
    return custom.isEmpty ? ident ?? '' : custom;
  }

  /// The line describing the airport under the logbook page, if any.
  String? get logbookNoteLine {
    if (!(logbookAnnotate ?? needsLogbookNote)) return null;
    final custom = logbookNote?.trim() ?? '';
    return custom.isEmpty ? defaultLogbookNote(logbookPlace) : custom;
  }

  /// Whether the logbook entry is overridden at all.
  bool get hasLogbookOverride =>
      (logbookIdent?.trim() ?? '').isNotEmpty ||
      logbookAnnotate != null ||
      (logbookNote?.trim() ?? '').isNotEmpty;

  /// [ident] as written in the logbook, then name, place and position.
  String defaultLogbookNote(String ident) {
    String dm(double v, String pos, String neg, int degDigits) {
      // In hundredths of a minute, so 59.996' can't print as 60.00'.
      final h = (v.abs() * 6000).round();
      final min = ((h % 6000) / 100).toStringAsFixed(2).padLeft(5, '0');
      return "${'${h ~/ 6000}'.padLeft(degDigits, '0')}°$min'${v < 0 ? neg : pos}";
    }

    final lat = latitudeDeg, lon = longitudeDeg;
    return [
      ident,
      [
        ?name,
        ?municipality,
        isoCountry,
      ].where((s) => s.trim().isNotEmpty).join(', '),
      if (lat != null && lon != null)
        '${dm(lat, 'N', 'S', 2)} ${dm(lon, 'E', 'W', 3)}',
      if (elevationFt != null) 'elev. $elevationFt ft',
    ].where((s) => s.isNotEmpty).join(' – ');
  }
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

  /// Null when the airport's country or region isn't in the dataset (yet),
  /// e.g. a custom airport added before the airport data was downloaded.
  final Country? country;
  final Region? region;
}

class FlightWithStats {
  FlightWithStats({
    required this.flight,
    required this.dataPoints,
    this.aircraftWithStats,
    this.simulator,
    this.departure,
    this.arrival,
  });
  final Flight flight;
  final List<FlightDataPoint> dataPoints;
  final AircraftWithStats? aircraftWithStats;

  /// The device of a simulator session (see [isSimulatorSession]).
  final SimulatorWithStats? simulator;
  final Airport? departure;
  final Airport? arrival;

  Duration? get duration =>
      flight.arrivalTime?.difference(flight.departureTime);

  late final int? maxAltitude = dataPoints.isEmpty
      ? null
      : dataPoints.map((p) => p.altitude).reduce(max);

  /// Whether this is a session in a flight simulation training device
  /// rather than a flight.
  bool get isSimulatorSession => flight.simulatorId != null;

  /// Length of the track, in kilometres.
  late final double? totalDistance = dataPoints.length < 2
      ? null
      : [
          for (var i = 1; i < dataPoints.length; i++)
            greatCircleKm(
              dataPoints[i - 1].latitude,
              dataPoints[i - 1].longitude,
              dataPoints[i].latitude,
              dataPoints[i].longitude,
            ),
        ].reduce((a, b) => a + b);

  /// This flight with its [track] loaded.
  FlightWithStats withTrack(List<FlightDataPoint> track) => FlightWithStats(
    flight: flight,
    dataPoints: track,
    aircraftWithStats: aircraftWithStats,
    simulator: simulator,
    departure: departure,
    arrival: arrival,
  );
}

/// A simulator with the aircraft type it represents and how much it was
/// used.
class SimulatorWithStats {
  const SimulatorWithStats({
    required this.simulator,
    this.type,
    this.sessionCount = 0,
    this.totalMinutes = 0,
  });

  final Simulator simulator;

  /// The aircraft type it represents, when it represents one.
  final IcaoAircraft? type;
  final int sessionCount;

  /// Total time of its sessions.
  final int totalMinutes;

  int get id => simulator.id;
  SimulatorKind get kind => simulator.kind;
  AircraftClass? get aircraftClass => simulator.aircraftClass;
  String? get typeRating => simulator.typeRating;

  /// Kind and level: "FFS D", "FNPT II".
  String get deviceLabel => simulator.kind.withLevel(simulator.level);

  /// What the device represents: its type rating, aircraft type or class.
  /// Null for a generic device.
  String? get represents {
    final rating = simulator.typeRating?.trim();
    if (rating != null && rating.isNotEmpty) return rating;
    if (type != null) return type!.designator;
    final c = simulator.aircraftClass;
    return c == null || c == AircraftClass.type ? null : c.label;
  }

  /// One line naming the device: "A320 FFS D", or "FNPT II" for a generic
  /// one.
  String get title => [?represents, deviceLabel].join(' ');

  /// The FSTD "type" column of the EASA logbook (AMC1 FCL.050(i)(9)(i)):
  /// the aircraft type and qualification number of an FFS or FTD
  /// ("B747-400 (Q1234)"), the kind and level of other devices ("FNPT II").
  String get logbookType {
    final number = simulator.qualificationNumber?.trim() ?? '';
    final type = represents;
    if (!simulator.kind.loggedByType || type == null) {
      return number.isEmpty ? deviceLabel : '$deviceLabel ($number)';
    }
    return number.isEmpty ? type : '$type ($number)';
  }
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
          aircrafts.aircraftClass,
          aircrafts.typeRating,
          aircrafts.photoFile,
          aircrafts.photoUrl,
          aircrafts.photoThumbnailUrl,
          aircrafts.photoLink,
          aircrafts.photoCredit,
          aircrafts.logbookType,
          aircrafts.logbookSubtitle,
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
          aircrafts.aircraftClass,
          aircrafts.typeRating,
          aircrafts.photoFile,
          aircrafts.photoUrl,
          aircrafts.photoThumbnailUrl,
          aircrafts.photoLink,
          aircrafts.photoCredit,
          aircrafts.logbookType,
          aircrafts.logbookSubtitle,
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

extension AircraftWithStatsPhoto on AircraftWithStats {
  /// The aircraft's photo, or null when it has none.
  AircraftPhoto? get photo => AircraftPhoto.fromColumns(
    file: photoFile,
    url: photoUrl,
    thumbnailUrl: photoThumbnailUrl,
    link: photoLink,
    credit: photoCredit,
  );
}

extension AircraftWithStatsLogbook on AircraftWithStats {
  /// What column 4 of the exported logbook says: the pilot's override, or
  /// the ICAO type designator.
  String get logbookTypeLine {
    final custom = logbookType?.trim() ?? '';
    return custom.isEmpty ? designator : custom;
  }

  /// The second line of column 4, when the pilot gave one.
  String? get logbookSubtitleLine {
    final custom = logbookSubtitle?.trim() ?? '';
    return custom.isEmpty ? null : custom;
  }

  /// Whether the logbook entry is overridden at all.
  bool get hasLogbookOverride =>
      (logbookType?.trim() ?? '').isNotEmpty ||
      (logbookSubtitle?.trim() ?? '').isNotEmpty;
}

extension ToIcaoAircraft on AircraftWithStats {
  IcaoAircraft toIcaoAircraft() {
    return IcaoAircraft(
      id: icaoAircraft,
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
    Simulators,
    IcaoAircrafts,
    People,
    FlightCrew,
    Licences,
    LicenceRatings,
    MedicalCertificates,
    PilotProfile,
  ],
  views: [AircraftWithStatss, AircraftWithIcaos],
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
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Columns are only added when missing: the migration tests start
      // from the current schema, where they already exist.
      Future<void> addMissing(
        TableInfo table,
        List<GeneratedColumn> columns,
      ) async {
        final existing = {
          for (final row in await customSelect(
            'PRAGMA table_info(${table.actualTableName})',
          ).get())
            row.read<String>('name'),
        };
        for (final column in columns) {
          if (!existing.contains(column.name)) {
            await m.addColumn(table, column);
          }
        }
      }

      if (from < 2) {
        await customStatement('ALTER TABLE flights ADD COLUMN pilot_role TEXT');
        await customStatement('ALTER TABLE flights ADD COLUMN crew_json TEXT');
      }
      if (from < 3) {
        await m.createTable(people);
        await m.createTable(flightCrew);
        await _migrateCrewJson();
        // Rebuild flights without the crew_json column.
        await m.alterTable(TableMigration(flights));
      }
      // Databases upgraded from < 3 got `people` with this column already.
      if (from == 3) {
        await m.addColumn(people, people.photo);
      }
      if (from < 5) {
        await addMissing(aircrafts, [
          aircrafts.aircraftClass,
          aircrafts.typeRating,
          aircrafts.photoFile,
          aircrafts.photoUrl,
          aircrafts.photoThumbnailUrl,
          aircrafts.photoLink,
          aircrafts.photoCredit,
        ]);
        // The aircraft views list the new columns.
        await m.recreateAllViews();
        await assignDeducedAircraftClasses();
      }
      if (from < 6) await addMissing(flights, [flights.trackSource]);
      if (from < 7) {
        await addMissing(flights, [
          flights.instrumentMinutes,
          flights.nightMinutes,
          flights.logbookOverrides,
        ]);
        await _backfillLogbookTimes();
      }
      if (from < 8) {
        // CREATE TABLE IF NOT EXISTS, like every createTable.
        await m.createTable(licences);
        await m.createTable(licenceRatings);
        await m.createTable(medicalCertificates);
      }
      if (from < 9) {
        final existing = {
          for (final row in await customSelect(
            'PRAGMA table_info(flights)',
          ).get())
            row.read<String>('name'),
        };
        if (!existing.contains(flights.proficiencyCheck.name)) {
          await m.addColumn(flights, flights.proficiencyCheck);
          // A flight with an examiner was, more often than not, a check.
          await customStatement(
            'UPDATE flights SET proficiency_check = 1 WHERE id IN '
            "(SELECT flight FROM flight_crew WHERE role = 'exm')",
          );
        }
      }
      if (from < 10) await addMissing(flights, [flights.signatureFile]);
      if (from < 11) {
        await m.createTable(simulators);
        await addMissing(flights, [flights.simulatorId]);
      }
      if (from < 12) await m.createTable(pilotProfile);
      if (from < 13) {
        await addMissing(licenceRatings, [licenceRatings.lightSingleEngine]);
        await addMissing(flights, [flights.mountainLandings]);
        await addMissing(pilotProfile, [pilotProfile.address]);
        await retireEnRouteInstrumentRatings();
      }
      if (from < 14) {
        await addMissing(aircrafts, [
          aircrafts.logbookType,
          aircrafts.logbookSubtitle,
        ]);
        await m.recreateAllViews();
      }
      if (from < 17) {
        await addMissing(airports, [
          airports.logbookIdent,
          airports.logbookAnnotate,
          airports.logbookNote,
        ]);
        // Schema 16 kept them in a table of their own (development only).
        await customStatement('DROP TABLE IF EXISTS airport_logbook_overrides');
      }
      if (from < 18) {
        // Indexes used to be declared where drift doesn't read them, so most
        // were never created.
        for (final index in allSchemaEntities.whereType<Index>()) {
          await customStatement(
            index.createStatementsByDialect.values.first.replaceFirst(
              'CREATE INDEX',
              'CREATE INDEX IF NOT EXISTS',
            ),
          );
        }
        await customStatement('DROP INDEX IF EXISTS flights_is_recording_idx');
        await customStatement('DROP VIEW IF EXISTS flight_stats');
      }
    },
  );

  /// The en route instrument rating (FCL.825) was deleted from Part-FCL:
  /// EIRs could only be used until 8 September 2022 (Article 4c). Ratings
  /// recorded as one become "other" ratings named EIR, kept for the record.
  Future<void> retireEnRouteInstrumentRatings() => customStatement(
    "UPDATE licence_ratings SET kind = 'other', "
    "name = COALESCE(NULLIF(TRIM(name), ''), 'EIR') "
    "WHERE kind = 'enRouteInstrument'",
  );

  /// Works out the instrument and night time of the flights logged before
  /// they were stored. Instrument time is only known for plain VFR and IFR
  /// flights: the others are left for the pilot.
  Future<void> _backfillLogbookTimes() async {
    final logged = await (select(
      flights,
    )..where((f) => f.arrivalTime.isNotNull())).get();
    for (final flight in logged) {
      final block = flight.arrivalTime!.difference(flight.departureTime);
      if (block.isNegative) continue;
      final instrument = switch (flight.flightRules) {
        null || 'VFR' => 0,
        'IFR' => block.inMinutes,
        _ => null,
      };
      await (update(flights)..where((f) => f.id.equals(flight.id))).write(
        FlightsCompanion(instrumentMinutes: Value(instrument)),
      );
      await updateNightTime(flight.id);
    }
  }

  /// Works the night time of [flightId] out again from what is stored: its
  /// airports, times and track. For when one of them changes outside the
  /// flight form (a track recorded, fetched or removed).
  Future<void> updateNightTime(int flightId) async {
    final departure = alias(airports, 'dep');
    final arrival = alias(airports, 'arr');
    final row = await (select(flights).join([
      leftOuterJoin(departure, flights.departure.equalsExp(departure.id)),
      leftOuterJoin(arrival, flights.arrival.equalsExp(arrival.id)),
    ])..where(flights.id.equals(flightId))).getSingleOrNull();
    if (row == null) return;
    final flight = row.readTable(flights);
    final track = await (select(
      flightDataPoints,
    )..where((p) => p.flight.equals(flightId))).get();
    final night = nightTimeOf(
      departureTime: flight.departureTime,
      arrivalTime: flight.arrivalTime,
      departure: row.readTableOrNull(departure),
      arrival: row.readTableOrNull(arrival),
      track: track.map((p) => p.timedPosition),
    );
    await (update(flights)..where((f) => f.id.equals(flightId))).write(
      FlightsCompanion(nightMinutes: Value(night?.inMinutes)),
    );
  }

  /// Gives every aircraft that has no class yet the class rating its type
  /// implies (see [AircraftClass.deduce]), so aircraft added before classes
  /// existed don't all have to be edited by hand. Aircraft that can't be
  /// told apart from their type alone, or that need a type rating (whose
  /// name only the pilot knows), are left for the user. Returns how many
  /// aircraft got a class.
  Future<int> assignDeducedAircraftClasses() async {
    final rows = await customSelect(
      'SELECT a.id AS id, t.description AS description, '
      't.engine_count AS engine_count, t.engine_type AS engine_type '
      'FROM aircrafts a JOIN icao_aircrafts t ON t.id = a.icao_aircraft '
      'WHERE a.aircraft_class IS NULL',
    ).get();
    var assigned = 0;
    for (final row in rows) {
      final description = AircraftDescription.values
          .asNameMap()[row.read<String>('description')];
      final engineType = EngineType.values
          .asNameMap()[row.read<String>('engine_type')];
      if (description == null || engineType == null) continue;
      final deduced = AircraftClass.deduce(
        description: description,
        engineCount: row.read<int>('engine_count'),
        engineType: engineType,
      );
      if (deduced == null || !deduced.isClassRating) continue;
      await customUpdate(
        'UPDATE aircrafts SET aircraft_class = ? WHERE id = ?',
        variables: [
          Variable.withString(deduced.name),
          Variable.withInt(row.read<int>('id')),
        ],
        updates: {aircrafts},
      );
      assigned++;
    }
    return assigned;
  }

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
    final row = await (select(airports).join([
      leftOuterJoin(countries, countries.code.equalsExp(airports.isoCountry)),
      leftOuterJoin(regions, regions.code.equalsExp(airports.isoRegion)),
    ])..where(airports.id.equals(airportId))).getSingleOrNull();
    if (row == null) return null;
    return AirportWithEverything(
      airport: row.readTable(airports),
      country: row.readTableOrNull(countries),
      region: row.readTableOrNull(regions),
      runways: await (select(
        runways,
      )..where((r) => r.airport.equals(airportId))).get(),
      frequencies: await (select(
        frequencies,
      )..where((f) => f.airport.equals(airportId))).get(),
    );
  }

  /// The airport known by the ICAO-style [code] ("LIMC"): its ident first,
  /// then its ICAO or GPS code. Null when none is.
  Future<Airport?> findAirportByCode(String code) async {
    final wanted = code.trim().toUpperCase();
    if (wanted.isEmpty) return null;
    final matches =
        await (select(airports)
              ..where(
                (a) =>
                    a.ident.upper().equals(wanted) |
                    a.icaoCode.upper().equals(wanted) |
                    a.gpsCode.upper().equals(wanted),
              )
              ..limit(10))
            .get();
    int rank(Airport a) {
      if (a.ident?.toUpperCase() == wanted) return 0;
      if (a.icaoCode?.toUpperCase() == wanted) return 1;
      return 2;
    }

    // A closed airport only when nothing open has the code.
    matches.sort((a, b) {
      final closed = (a.type == AirportType.closed ? 1 : 0).compareTo(
        b.type == AirportType.closed ? 1 : 0,
      );
      return closed != 0 ? closed : rank(a).compareTo(rank(b));
    });
    return matches.firstOrNull;
  }

  /// Airports within [delta] degrees of the coordinates.
  Future<List<Airport>> getAirportsWithinSquare(
    double latitude,
    double longitude, {
    double delta = 2.0,
  }) {
    return (select(airports)..where(
          (a) =>
              a.latitudeDeg.isBetweenValues(
                latitude - delta,
                latitude + delta,
              ) &
              a.longitudeDeg.isBetweenValues(
                longitude - delta,
                longitude + delta,
              ),
        ))
        .get();
  }

  /// Adds an ICAO type of the user's own.
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

  /// Deletes a flight with its track and crew, atomically.
  Future<void> deleteFlight(int flightId) => transaction(() async {
    await (delete(
      flightDataPoints,
    )..where((p) => p.flight.equals(flightId))).go();
    await (delete(flightCrew)..where((c) => c.flight.equals(flightId))).go();
    await (delete(flights)..where((f) => f.id.equals(flightId))).go();
  });

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
