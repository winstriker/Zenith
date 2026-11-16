import 'dart:async';

import '../models/flight_track.dart';
import 'adsb_track_source.dart';
import 'database.dart';
import 'registry_database.dart';

/// How an airport of an imported flight was arrived at.
enum ImportedAirportOrigin {
  /// The provider named it, and it is in the airport database.
  route,

  /// Where the flight's callsign usually goes: the landing wasn't seen.
  usualRoute,

  /// The nearest airport to where the track starts (or ends).
  nearest,
}

/// An airport of an imported flight, and how it was found.
class ImportedAirport {
  const ImportedAirport(this.airport, this.origin, {this.distanceKm});
  final Airport airport;
  final ImportedAirportOrigin origin;

  /// From the end of the track, for [ImportedAirportOrigin.nearest].
  final double? distanceKm;
}

/// Everything a flight seen on ADS-B tells about the flight to log: filled
/// into the flight form, which the user checks and saves.
class AdsbImportDraft {
  const AdsbImportDraft({
    required this.flight,
    required this.points,
    this.departure,
    this.arrival,
    this.registration,
    this.aircraft,
  });

  final AdsbFlight flight;

  /// The track, ready to be stored: in order, every point with an altitude.
  /// At least two points.
  final List<TrackPoint> points;

  final ImportedAirport? departure;
  final ImportedAirport? arrival;

  /// The registration of the aircraft, when it could be found out. Spelled
  /// as the user or an online registry spells it ("EI-DCL") when possible.
  final String? registration;

  /// The user's aircraft with [registration], when there is one.
  final AircraftWithStats? aircraft;

  /// When the provider first and last saw the flight, UTC. ADS-B can't
  /// tell off- and on-block times; these are the nearest thing it has.
  /// Not the ends of [points]: a provider's track can stop short of what
  /// it saw of the flight.
  DateTime get departureTime => flight.start;

  /// Null when the landing wasn't seen: when the aircraft was last heard
  /// says nothing of when it landed.
  DateTime? get arrivalTime => flight.arrivalUnseen ? null : flight.end;
}

/// Turns a flight found on ADS-B into an [AdsbImportDraft]: fetches its
/// track, works out its airports and which of the user's aircraft flew it.
///
/// Takes its lookups as functions so that it can be tested without a
/// database or network.
class AdsbFlightImporter {
  AdsbFlightImporter({
    required this.fetchPoints,
    required this.airportByCode,
    required this.airportsNear,
    required this.localRegistrations,
    required this.onlineRegistration,
    required this.aircraft,
  });

  /// The track of a flight, with altitudes as sent (see
  /// `AdsbTrackService.fetchPoints`).
  final Future<List<TrackPoint>> Function(AdsbFlight flight) fetchPoints;

  /// The airport with an ICAO-style code, if the database has it.
  final Future<Airport?> Function(String code) airportByCode;

  /// Airports around a position, nearest first.
  final Future<List<AirportWithDistance>> Function(double lat, double lon)
  airportsNear;

  /// Registrations the downloaded registry files under an ICAO address,
  /// normalized ("EIDCL"). Empty when it has none or is switched off.
  final Future<List<String>> Function(String hex) localRegistrations;

  /// The registration an online registry gives an ICAO address, as it
  /// spells it. Null when it doesn't know, can't be asked or is off.
  final Future<String?> Function(String hex) onlineRegistration;

  /// The user's aircraft.
  final Future<List<AircraftWithStats>> Function() aircraft;

  /// How long the online registry is waited for: the import goes on
  /// without it.
  static const onlineTimeout = Duration(seconds: 8);

  /// [typedRegistration] is what the user searched for, when the search was
  /// by registration.
  Future<AdsbImportDraft> prepare(
    AdsbFlight flight, {
    String? typedRegistration,
  }) async {
    final raw = await fetchPoints(flight);
    if (raw.length < 2) {
      throw AdsbException(
        '${flight.provider.label} has no positions for this flight.',
      );
    }

    final (departure, arrival, (registration, aircraft)) = await (
      _airport(flight.departure, raw.first, flight.start),
      _airport(
        flight.arrival,
        raw.last,
        flight.end,
        origin: flight.arrivalUnseen
            ? ImportedAirportOrigin.usualRoute
            : ImportedAirportOrigin.route,
      ),
      _aircraft(flight, typedRegistration),
    ).wait;

    double? metres(ImportedAirport? airport) {
      final feet = airport?.airport.elevationFt;
      return feet == null ? null : feet * TrackTools.feetToMetres;
    }

    return AdsbImportDraft(
      flight: flight,
      points: TrackTools.fillAltitudes(
        raw,
        departureElevation: metres(departure),
        arrivalElevation: metres(arrival),
      ),
      departure: departure,
      arrival: arrival,
      registration: registration,
      aircraft: aircraft,
    );
  }

  // ---------------------------------------------------------------------------
  // Airports
  // ---------------------------------------------------------------------------

  /// How far the end of a track may be, in time, from the end of the
  /// flight for the airport nearest to it to be a fair guess.
  static const trackReachSlack = Duration(minutes: 20);

  /// The airport at one end of a flight: the one with [code], or the one
  /// nearest [end], the track's point at that end. [flightEnd] is when the
  /// provider saw the flight start (or end): when the track stops well
  /// short of it, the nearest airport to the track says nothing.
  Future<ImportedAirport?> _airport(
    String? code,
    TrackPoint end,
    DateTime flightEnd, {
    ImportedAirportOrigin origin = ImportedAirportOrigin.route,
  }) async {
    if (code != null) {
      final airport = await airportByCode(code);
      if (airport != null) return ImportedAirport(airport, origin);
    }
    if (end.time.difference(flightEnd).abs() > trackReachSlack) return null;
    final near = pickNearest(await airportsNear(end.latitude, end.longitude));
    return near == null
        ? null
        : ImportedAirport(
            near.airport,
            ImportedAirportOrigin.nearest,
            distanceKm: near.distance,
          );
  }

  /// A heliport is only taken when the track ends right on it and no
  /// aerodrome is near: an aerodrome's reference point can be a kilometre
  /// or two from its apron, and the hospital helipad next door is no
  /// guess for an aeroplane.
  static const _helipadKm = 0.3;
  static const _aerodromeKm = 2.0;

  /// The airport an aircraft at the centre of [nearby] (nearest first) is
  /// most likely at. Closed airports and balloon ports are no answer.
  static AirportWithDistance? pickNearest(List<AirportWithDistance> nearby) {
    final open = [
      for (final candidate in nearby)
        if (candidate.airport.type != AirportType.closed &&
            candidate.airport.type != AirportType.balloonport)
          candidate,
    ]..sort((a, b) => a.distance.compareTo(b.distance));
    final aerodrome = open
        .where((c) => c.airport.type != AirportType.heliport)
        .firstOrNull;
    final heliport = open
        .where((c) => c.airport.type == AirportType.heliport)
        .firstOrNull;
    if (heliport != null &&
        heliport.distance <= _helipadKm &&
        (aerodrome == null || aerodrome.distance > _aerodromeKm)) {
      return heliport;
    }
    return aerodrome ?? heliport;
  }

  // ---------------------------------------------------------------------------
  // Aircraft
  // ---------------------------------------------------------------------------

  /// The registration of the aircraft that flew [flight] and the user's
  /// aircraft with it, if any.
  Future<(String?, AircraftWithStats?)> _aircraft(
    AdsbFlight flight,
    String? typedRegistration,
  ) async {
    final typed = _clean(typedRegistration);
    final (mine, local) = await (
      aircraft(),
      _orNone(() => localRegistrations(flight.icao24)),
    ).wait;

    // Light aircraft often transmit their registration as callsign
    // ("IABCD" for I-ABCD): worth trying against the user's aircraft.
    final candidates = [?typed, ...local, ?_clean(flight.callsign)];
    final match = matchAircraft(mine, candidates);
    if (match != null) return (match.tailNumber, match);

    // Not one of the user's: a spelling worth prefilling a new aircraft
    // with. Only the registry's, typed in or not: a callsign is no proof.
    String? online;
    try {
      online = await onlineRegistration(flight.icao24).timeout(onlineTimeout);
    } catch (_) {
      online = null;
    }
    final registration =
        _clean(online) ?? typed ?? (local.isEmpty ? null : local.first);
    // The online registry may spell it in a way that matches after all.
    final late = registration == null
        ? null
        : matchAircraft(mine, [registration]);
    return (late?.tailNumber ?? registration, late);
  }

  /// The aircraft of [mine] whose registration is one of [registrations],
  /// whatever the spelling ("EI-DCL", "eidcl"). The first registration
  /// that matches wins.
  static AircraftWithStats? matchAircraft(
    List<AircraftWithStats> mine,
    List<String> registrations,
  ) {
    final byKey = <String, AircraftWithStats>{};
    for (final aircraft in mine) {
      final key = RegistryDatabase.normalizeRegistration(aircraft.tailNumber);
      if (key.isNotEmpty) byKey.putIfAbsent(key, () => aircraft);
    }
    for (final registration in registrations) {
      final match = byKey[RegistryDatabase.normalizeRegistration(registration)];
      if (match != null) return match;
    }
    return null;
  }

  /// What [lookup] finds, or nothing when it fails: a registry that can't
  /// be read is no reason not to import.
  static Future<List<String>> _orNone(
    Future<List<String>> Function() lookup,
  ) async {
    try {
      return await lookup();
    } catch (_) {
      return const [];
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim().toUpperCase() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
