import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/crew_rules.dart';
import '../models/logbook_entry.dart';
import '../services/database.dart';
import '../utils/night_time.dart';
import '../utils/tz_datetime.dart';

enum TimezoneMode { utc, local, iana }

class FlightFormState {
  FlightFormState({
    this.departureCode = '',
    this.arrivalCode = '',
    this.depTime = '',
    this.arrTime = '',
    this.remarks = '',
    this.selectedDeparture,
    this.selectedArrival,
    DateTime? departureDate,
    this.arrivalDate,
    this.depTzMode = TimezoneMode.local,
    this.arrTzMode = TimezoneMode.local,
    this.depIanaLocation,
    this.arrIanaLocation,
    this.deviceZone = 'UTC',
    this.selectedAircraft,
    this.isSimulator = false,
    this.selectedSimulator,
    this.approachType = 'VISUAL',
    this.nightLandings = 0,
    this.dayLandings = 1,
    this.mountainLandings = 0,
    this.flightRules = 'VFR',
    this.instrumentMinutes,
    this.pilotRole = CrewRole.pic,
    List<CrewMember>? crewMembers,
    this.proficiencyCheck = true,
    this.track = const [],
  }) : departureDate = departureDate ?? DateTime.now(),
       crewMembers = crewMembers ?? const [];

  final String departureCode;
  final String arrivalCode;
  final String depTime;
  final String arrTime;
  final String remarks;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final DateTime departureDate;
  final DateTime? arrivalDate;
  final TimezoneMode depTzMode;
  final TimezoneMode arrTzMode;

  /// The zones picked by hand, for [TimezoneMode.iana]. What the times are
  /// in is [depZone] and [arrZone].
  final String? depIanaLocation;
  final String? arrIanaLocation;

  /// The time zone of the phone: what is local without an airport.
  final String deviceZone;
  final AircraftWithStats? selectedAircraft;

  /// Whether this is a session in a simulator rather than a flight: no
  /// airports, aircraft or flight rules, and times in the device's (the
  /// phone's) time zone, or the one it was saved in.
  final bool isSimulator;
  final SimulatorWithStats? selectedSimulator;
  final String approachType;
  final int nightLandings;
  final int dayLandings;

  /// How many of the landings were on surfaces designated to require a
  /// mountain rating (FCL.815(d)).
  final int mountainLandings;
  final String flightRules;

  /// IFR time the pilot entered, for flights that change rules on the way.
  /// VFR and IFR flights don't use it: theirs follows from the block time.
  final int? instrumentMinutes;
  final CrewRole pilotRole;
  final List<CrewMember> crewMembers;

  /// Whether the flight is a proficiency check, as the pilot ticked it.
  /// Only asked, and only saved, when an examiner is in the crew: see
  /// [isProficiencyCheck].
  final bool proficiencyCheck;

  /// The flight's track (recorded, or from ADS-B), when it has one: the
  /// route night time is worked out along.
  final List<TimedPosition> track;

  FlightFormState copyWith({
    String? departureCode,
    String? arrivalCode,
    String? depTime,
    String? arrTime,
    String? remarks,
    Airport? selectedDeparture,
    Airport? selectedArrival,
    DateTime? departureDate,
    DateTime? arrivalDate,
    TimezoneMode? depTzMode,
    TimezoneMode? arrTzMode,
    String? depIanaLocation,
    String? arrIanaLocation,
    AircraftWithStats? selectedAircraft,
    bool? isSimulator,
    SimulatorWithStats? selectedSimulator,
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    int? mountainLandings,
    String? flightRules,
    int? instrumentMinutes,
    CrewRole? pilotRole,
    List<CrewMember>? crewMembers,
    bool? proficiencyCheck,
    List<TimedPosition>? track,
    bool clearInstrument = false,
    bool clearArrivalDate = false,
    bool clearDepIana = false,
    bool clearArrIana = false,
  }) {
    return FlightFormState(
      departureCode: departureCode ?? this.departureCode,
      arrivalCode: arrivalCode ?? this.arrivalCode,
      depTime: depTime ?? this.depTime,
      arrTime: arrTime ?? this.arrTime,
      remarks: remarks ?? this.remarks,
      selectedDeparture: selectedDeparture ?? this.selectedDeparture,
      selectedArrival: selectedArrival ?? this.selectedArrival,
      departureDate: departureDate ?? this.departureDate,
      arrivalDate: clearArrivalDate ? null : (arrivalDate ?? this.arrivalDate),
      depTzMode: depTzMode ?? this.depTzMode,
      arrTzMode: arrTzMode ?? this.arrTzMode,
      depIanaLocation: clearDepIana
          ? null
          : (depIanaLocation ?? this.depIanaLocation),
      arrIanaLocation: clearArrIana
          ? null
          : (arrIanaLocation ?? this.arrIanaLocation),
      deviceZone: deviceZone,
      selectedAircraft: selectedAircraft ?? this.selectedAircraft,
      isSimulator: isSimulator ?? this.isSimulator,
      selectedSimulator: selectedSimulator ?? this.selectedSimulator,
      approachType: approachType ?? this.approachType,
      nightLandings: nightLandings ?? this.nightLandings,
      dayLandings: dayLandings ?? this.dayLandings,
      mountainLandings: mountainLandings ?? this.mountainLandings,
      flightRules: flightRules ?? this.flightRules,
      instrumentMinutes: clearInstrument
          ? null
          : (instrumentMinutes ?? this.instrumentMinutes),
      pilotRole: pilotRole ?? this.pilotRole,
      crewMembers: crewMembers ?? this.crewMembers,
      proficiencyCheck: proficiencyCheck ?? this.proficiencyCheck,
      track: track ?? this.track,
    );
  }

  /// The time zone the departure's date and time are in.
  String get depZone => isSimulator
      ? depIanaLocation ?? deviceZone
      : _zone(depTzMode, selectedDeparture, depIanaLocation);

  /// The time zone the arrival's date and time are in.
  String get arrZone => isSimulator
      ? depZone
      : _zone(arrTzMode, selectedArrival, arrIanaLocation);

  String _zone(TimezoneMode mode, Airport? airport, String? ianaLocation) =>
      switch (mode) {
        TimezoneMode.utc => 'UTC',
        TimezoneMode.local =>
          TZDateTimeParser.locationAt(
                airport?.latitudeDeg,
                airport?.longitudeDeg,
              )?.name ??
              deviceZone,
        TimezoneMode.iana => ianaLocation ?? 'UTC',
      };

  String get depTzLabel =>
      depTzMode == TimezoneMode.local && selectedDeparture == null
      ? 'LCL'
      : depTZDateTime.timeZone.abbreviation;

  String get arrTzLabel =>
      arrTzMode == TimezoneMode.local && selectedArrival == null
      ? 'LCL'
      : (arrTZDateTime ??
                TZDateTimeParser.parseDateTimeFromText(
                  arrTime,
                  arrivalDate ?? departureDate,
                  arrZone,
                ))
            .timeZone
            .abbreviation;

  tz.TZDateTime get depTZDateTime =>
      TZDateTimeParser.parseDateTimeFromText(depTime, departureDate, depZone);

  /// On [arrivalDate]; without one (or in a simulator) the first time it is
  /// [arrTime] there after the departure.
  tz.TZDateTime? get arrTZDateTime {
    if (arrTime.isEmpty) return null;
    final date = isSimulator ? null : arrivalDate;
    if (date != null) {
      return TZDateTimeParser.parseDateTimeFromText(arrTime, date, arrZone);
    }
    if (depTime.isEmpty) return null;
    final departure = depTZDateTime;
    final day = tz.TZDateTime.from(
      departure,
      TZDateTimeParser.location(arrZone),
    );
    final arrival = TZDateTimeParser.parseDateTimeFromText(
      arrTime,
      day,
      arrZone,
    );
    return arrival.isBefore(departure)
        ? TZDateTimeParser.parseDateTimeFromText(
            arrTime,
            DateTime(day.year, day.month, day.day + 1),
            arrZone,
          )
        : arrival;
  }

  /// Non-null when the times can't be right.
  String? get timeError {
    final arrival = arrTZDateTime;
    if (depTime.isNotEmpty &&
        TZDateTimeParser.isSkipped(depTime, depTZDateTime)) {
      return 'The clocks skip $depTime on the departure date';
    }
    if (arrival != null && TZDateTimeParser.isSkipped(arrTime, arrival)) {
      return 'The clocks skip $arrTime on the arrival date';
    }
    return blockTime?.isNegative ?? false
        ? 'The arrival is before the departure'
        : null;
  }

  Duration? get blockTime {
    final arr = arrTZDateTime;
    if (arr == null || depTime.isEmpty) return null;
    return arr.difference(depTZDateTime);
  }

  FlightRulesKind get rulesKind => FlightRulesKind.of(flightRules);

  /// Block time, or null when it isn't known or makes no sense.
  Duration? get _validBlockTime {
    final d = blockTime;
    return d == null || d.isNegative ? null : d;
  }

  /// Time under IFR: none for VFR, the block time for IFR, what was entered
  /// otherwise. Null when not known yet.
  Duration? get instrumentTime => switch (rulesKind) {
    FlightRulesKind.vfr => Duration.zero,
    FlightRulesKind.ifr => _validBlockTime,
    FlightRulesKind.mixed =>
      instrumentMinutes == null ? null : Duration(minutes: instrumentMinutes!),
  };

  /// Time under VFR: the rest of the block time.
  Duration? get visualTime {
    final block = _validBlockTime;
    final instrument = instrumentTime;
    if (block == null || instrument == null) return null;
    return block - instrument;
  }

  /// Non-null when the IFR time entered doesn't fit in the block time.
  String? get instrumentError {
    if (rulesKind != FlightRulesKind.mixed) return null;
    final block = _validBlockTime;
    final instrument = instrumentTime;
    if (block == null || instrument == null) return null;
    return instrument.isNegative || instrument > block
        ? 'IFR and VFR time must add up to the block time'
        : null;
  }

  /// Time flown at night (after civil twilight), along the track when there
  /// is one, between the airports otherwise. Null when it can't be worked
  /// out.
  Duration? get nightTime => nightTimeOf(
    departureTime: depTZDateTime,
    arrivalTime: depTime.isEmpty ? null : arrTZDateTime,
    departure: selectedDeparture,
    arrival: selectedArrival,
    track: track,
  );

  /// Whether someone in the crew flew as examiner.
  bool get hasExaminer => crewMembers.any((m) => m.role == CrewRole.exm);

  /// What gets saved: a proficiency check needs an examiner.
  bool get isProficiencyCheck => hasExaminer && proficiencyCheck;

  /// Non-null when SELF's role and the crew roles are inconsistent.
  String? get crewError => crewValidationError(pilotRole, crewMembers);

  bool get isValid {
    if (isSimulator) {
      final session = blockTime;
      return selectedSimulator != null &&
          depTime.isNotEmpty &&
          session != null &&
          session > Duration.zero &&
          timeError == null &&
          crewError == null;
    }
    return departureCode.isNotEmpty &&
        arrivalCode.isNotEmpty &&
        depTime.isNotEmpty &&
        timeError == null &&
        crewError == null &&
        (rulesKind != FlightRulesKind.mixed || instrumentMinutes != null) &&
        instrumentError == null;
  }
}

class FlightFormNotifier extends Notifier<FlightFormState> {
  @override
  FlightFormState build() => FlightFormState(
    depTime: TZDateTimeParser.formatHHmm(TimeOfDay.now()),
    deviceZone: TZDateTimeParser.deviceZone(),
  );

  void setDepartureCode(String code) =>
      state = state.copyWith(departureCode: code);
  void setArrivalCode(String code) => state = state.copyWith(arrivalCode: code);
  void setDepTime(String time) => state = state.copyWith(depTime: time);
  void setArrTime(String time) => state = state.copyWith(arrTime: time);
  void setRemarks(String text) => state = state.copyWith(remarks: text);

  static String _codeOf(Airport airport) =>
      airport.ident ??
      airport.icaoCode ??
      airport.iataCode ??
      airport.name ??
      '';

  /// In local time mode, the times follow the airport's time zone.
  void setSelectedDeparture(Airport? airport) {
    if (airport == null) return;
    state = state.copyWith(
      selectedDeparture: airport,
      departureCode: _codeOf(airport),
    );
  }

  /// In local time mode, the times follow the airport's time zone.
  void setSelectedArrival(Airport? airport) {
    if (airport == null) return;
    state = state.copyWith(
      selectedArrival: airport,
      arrivalCode: _codeOf(airport),
    );
  }

  void setDepartureDate(DateTime date) =>
      state = state.copyWith(departureDate: date);
  void setArrivalDate(DateTime? date) =>
      state = state.copyWith(arrivalDate: date, clearArrivalDate: date == null);

  /// Sets date and time to those of [instant] in the departure's zone, or in
  /// UTC when they come twice there (the clocks go back) and would be read as
  /// the other one.
  void setDepInstant(DateTime instant) {
    void show() {
      final t = tz.TZDateTime.from(
        instant,
        TZDateTimeParser.location(state.depZone),
      );
      state = state.copyWith(
        departureDate: DateTime(t.year, t.month, t.day),
        depTime: TZDateTimeParser.formatHHmm(TimeOfDay.fromDateTime(t)),
      );
    }

    show();
    if (state.depTZDateTime.difference(instant).inMinutes == 0) return;
    setDepIanaLocation('UTC');
    show();
  }

  /// As [setDepInstant], for the arrival. Its date is only set when it isn't
  /// the one worked out, so that it follows the departure's.
  void setArrInstant(DateTime instant) {
    bool shown() => state.arrTZDateTime?.difference(instant).inMinutes == 0;
    void show() {
      final t = tz.TZDateTime.from(
        instant,
        TZDateTimeParser.location(state.arrZone),
      );
      state = state.copyWith(
        arrTime: TZDateTimeParser.formatHHmm(TimeOfDay.fromDateTime(t)),
        clearArrivalDate: true,
      );
      if (shown()) return;
      state = state.copyWith(arrivalDate: DateTime(t.year, t.month, t.day));
    }

    show();
    if (shown()) return;
    setArrIanaLocation('UTC');
    show();
  }

  void setDepTzMode(TimezoneMode mode) => state = state.copyWith(
    depTzMode: mode,
    clearDepIana: mode != TimezoneMode.iana,
  );

  void setArrTzMode(TimezoneMode mode) => state = state.copyWith(
    arrTzMode: mode,
    clearArrIana: mode != TimezoneMode.iana,
  );

  void setDepIanaLocation(String? location) => state = state.copyWith(
    depIanaLocation: location,
    depTzMode: TimezoneMode.iana,
  );
  void setArrIanaLocation(String? location) => state = state.copyWith(
    arrIanaLocation: location,
    arrTzMode: TimezoneMode.iana,
  );

  void setSelectedAircraft(AircraftWithStats? aircraft) =>
      state = state.copyWith(selectedAircraft: aircraft);

  /// Switches between logging a flight and a simulator session. A session
  /// starts without landings: they would count for recency (FCL.060).
  void setSimulator(bool isSimulator) {
    if (isSimulator == state.isSimulator) return;
    state = state.copyWith(
      isSimulator: isSimulator,
      // A zone picked for a flight isn't the session's.
      depTzMode: TimezoneMode.local,
      clearDepIana: true,
      dayLandings: isSimulator ? 0 : 1,
      nightLandings: 0,
      mountainLandings: 0,
    );
  }

  void setSelectedSimulator(SimulatorWithStats? simulator) =>
      state = state.copyWith(selectedSimulator: simulator);
  void setApproachType(String type) =>
      state = state.copyWith(approachType: type);
  void setNightLandings(int count) =>
      state = state.copyWith(nightLandings: count);
  void setDayLandings(int count) => state = state.copyWith(dayLandings: count);
  void setMountainLandings(int count) =>
      state = state.copyWith(mountainLandings: count);
  void setFlightRules(String rules) =>
      state = state.copyWith(flightRules: rules);

  /// IFR time of a flight that changes rules: the VFR time is the rest.
  void setInstrumentTime(Duration? time) => state = time == null
      ? state.copyWith(clearInstrument: true)
      : state.copyWith(instrumentMinutes: time.inMinutes);

  /// VFR time of a flight that changes rules: the IFR time is the rest.
  /// Needs the block time.
  void setVisualTime(Duration? time) {
    final block = state.blockTime;
    if (time == null || block == null || block.isNegative) {
      state = state.copyWith(clearInstrument: true);
      return;
    }
    state = state.copyWith(instrumentMinutes: (block - time).inMinutes);
  }

  void setTrack(List<TimedPosition> track) =>
      state = state.copyWith(track: track);

  void setPilotRole(CrewRole role) => state = state.copyWith(pilotRole: role);

  void addCrewMember(CrewMember member) =>
      _setCrew([...state.crewMembers, member]);

  void removeCrewMember(int index) =>
      _setCrew([...state.crewMembers]..removeAt(index));

  void updateCrewMember(int index, CrewMember member) =>
      _setCrew([...state.crewMembers]..[index] = member);

  void setProficiencyCheck(bool value) =>
      state = state.copyWith(proficiencyCheck: value);

  /// An examiner joining the crew ticks the proficiency check again: it is
  /// what a flight with an examiner usually is.
  void _setCrew(List<CrewMember> crew) {
    final examinerAdded =
        !state.hasExaminer && crew.any((m) => m.role == CrewRole.exm);
    state = state.copyWith(
      crewMembers: crew,
      proficiencyCheck: examinerAdded ? true : null,
    );
  }

  void reset() => state = build();
}

final flightFormProvider =
    NotifierProvider<FlightFormNotifier, FlightFormState>(
      FlightFormNotifier.new,
    );
