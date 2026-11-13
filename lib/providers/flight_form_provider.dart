import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/database.dart';
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
    this.selectedAircraft,
    this.approachType = 'VISUAL',
    this.nightLandings = 0,
    this.dayLandings = 1,
    this.flightRules = 'VFR',
    this.pilotRole = CrewRole.pic,
    List<CrewMember>? crewMembers,
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
  final String? depIanaLocation;
  final String? arrIanaLocation;
  final AircraftWithStats? selectedAircraft;
  final String approachType;
  final int nightLandings;
  final int dayLandings;
  final String flightRules;
  final CrewRole pilotRole;
  final List<CrewMember> crewMembers;

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
    String? approachType,
    int? nightLandings,
    int? dayLandings,
    String? flightRules,
    CrewRole? pilotRole,
    List<CrewMember>? crewMembers,
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
      selectedAircraft: selectedAircraft ?? this.selectedAircraft,
      approachType: approachType ?? this.approachType,
      nightLandings: nightLandings ?? this.nightLandings,
      dayLandings: dayLandings ?? this.dayLandings,
      flightRules: flightRules ?? this.flightRules,
      pilotRole: pilotRole ?? this.pilotRole,
      crewMembers: crewMembers ?? this.crewMembers,
    );
  }

  String get depTzLabel {
    switch (depTzMode) {
      case TimezoneMode.utc:
        return 'UTC';
      case TimezoneMode.local:
        return _airportTimezone(selectedDeparture);
      case TimezoneMode.iana:
        return TZDateTimeParser.parseDateTimeFromText(
          depTime,
          departureDate,
          depIanaLocation,
        ).timeZone.abbreviation;
    }
  }

  String get arrTzLabel {
    switch (arrTzMode) {
      case TimezoneMode.utc:
        return 'UTC';
      case TimezoneMode.local:
        return _airportTimezone(selectedArrival);
      case TimezoneMode.iana:
        if (arrivalDate == null) return 'IANA';
        return TZDateTimeParser.parseDateTimeFromText(
          arrTime,
          arrivalDate!,
          arrIanaLocation,
        ).timeZone.abbreviation;
    }
  }

  String _airportTimezone(Airport? airport) {
    if (airport == null) return 'LCL';
    if (airport.latitudeDeg == null || airport.longitudeDeg == null) {
      return 'LCL';
    }

    try {
      final ianaLocation = latLngToTimezoneString(
        airport.latitudeDeg!,
        airport.longitudeDeg!,
      );

      final location = tz.getLocation(ianaLocation);
      final now = tz.TZDateTime.now(location);
      return now.timeZone.abbreviation;
    } catch (_) {
      return 'LCL';
    }
  }

  tz.TZDateTime get depTZDateTime => TZDateTimeParser.parseDateTimeFromText(
    depTime,
    departureDate,
    depIanaLocation,
  );

  tz.TZDateTime? get arrTZDateTime {
    if (arrTime.isEmpty || arrivalDate == null) return null;
    return TZDateTimeParser.parseDateTimeFromText(
      arrTime,
      arrivalDate!,
      arrIanaLocation,
    );
  }

  Duration? get blockTime {
    final arr = arrTZDateTime;
    if (arr == null) return null;
    return arr.difference(depTZDateTime);
  }

  String get blockTimeFormatted {
    final d = blockTime;
    if (d == null || d.isNegative) return '0:00';
    final m = d.inMinutes;
    return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  }

  bool get isValid {
    return departureCode.isNotEmpty &&
        arrivalCode.isNotEmpty &&
        depTime.isNotEmpty;
  }
}

class FlightFormNotifier extends Notifier<FlightFormState> {
  @override
  FlightFormState build() {
    final state = FlightFormState();
    return state.copyWith(
      depTime: TZDateTimeParser.formatHHmm(TimeOfDay.now()),
    );
  }

  void setDepartureCode(String code) =>
      state = state.copyWith(departureCode: code);
  void setArrivalCode(String code) => state = state.copyWith(arrivalCode: code);
  void setDepTime(String time) => state = state.copyWith(depTime: time);
  void setArrTime(String time) => state = state.copyWith(arrTime: time);
  void setRemarks(String text) => state = state.copyWith(remarks: text);

  void setSelectedDeparture(Airport? airport) {
    if (airport != null) {
      final code =
          airport.ident ??
          airport.icaoCode ??
          airport.iataCode ??
          airport.name ??
          '';
      // If in local mode, update the IANA location to match airport's timezone
      if (state.depTzMode == TimezoneMode.local &&
          airport.latitudeDeg != null &&
          airport.longitudeDeg != null) {
        try {
          final ianaLocation = latLngToTimezoneString(
            airport.latitudeDeg!,
            airport.longitudeDeg!,
          );
          state = state.copyWith(
            selectedDeparture: airport,
            departureCode: code,
            depIanaLocation: ianaLocation,
          );
        } catch (_) {
          state = state.copyWith(
            selectedDeparture: airport,
            departureCode: code,
          );
        }
      } else {
        state = state.copyWith(selectedDeparture: airport, departureCode: code);
      }
    } else {
      state = state.copyWith();
    }
  }

  void setSelectedArrival(Airport? airport) {
    if (airport != null) {
      final code =
          airport.ident ??
          airport.icaoCode ??
          airport.iataCode ??
          airport.name ??
          '';
      // If in local mode, update the IANA location to match airport's timezone
      if (state.arrTzMode == TimezoneMode.local &&
          airport.latitudeDeg != null &&
          airport.longitudeDeg != null) {
        try {
          final ianaLocation = latLngToTimezoneString(
            airport.latitudeDeg!,
            airport.longitudeDeg!,
          );
          state = state.copyWith(
            selectedArrival: airport,
            arrivalCode: code,
            arrIanaLocation: ianaLocation,
          );
        } catch (_) {
          state = state.copyWith(selectedArrival: airport, arrivalCode: code);
        }
      } else {
        state = state.copyWith(selectedArrival: airport, arrivalCode: code);
      }
    } else {
      state = state.copyWith();
    }
  }

  void setDepartureDate(DateTime date) =>
      state = state.copyWith(departureDate: date);
  void setArrivalDate(DateTime? date) =>
      state = state.copyWith(arrivalDate: date, clearArrivalDate: date == null);

  void setDepTzMode(TimezoneMode mode) {
    if (mode != TimezoneMode.iana) {
      state = state.copyWith(depTzMode: mode, clearDepIana: true);
    } else {
      state = state.copyWith(depTzMode: mode);
    }
  }

  void setArrTzMode(TimezoneMode mode) {
    if (mode != TimezoneMode.iana) {
      state = state.copyWith(arrTzMode: mode, clearArrIana: true);
    } else {
      state = state.copyWith(arrTzMode: mode);
    }
  }

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
  void setApproachType(String type) =>
      state = state.copyWith(approachType: type);
  void setNightLandings(int count) =>
      state = state.copyWith(nightLandings: count);
  void setDayLandings(int count) => state = state.copyWith(dayLandings: count);
  void setFlightRules(String rules) =>
      state = state.copyWith(flightRules: rules);

  void incrementNightLandings() =>
      state = state.copyWith(nightLandings: state.nightLandings + 1);
  void decrementNightLandings() => state = state.copyWith(
    nightLandings: (state.nightLandings - 1).clamp(0, 99),
  );
  void incrementDayLandings() =>
      state = state.copyWith(dayLandings: state.dayLandings + 1);
  void decrementDayLandings() =>
      state = state.copyWith(dayLandings: (state.dayLandings - 1).clamp(0, 99));

  void setPilotRole(CrewRole role) => state = state.copyWith(pilotRole: role);

  void addCrewMember(CrewMember member) =>
      state = state.copyWith(crewMembers: [...state.crewMembers, member]);

  void removeCrewMember(int index) {
    final updated = [...state.crewMembers];
    updated.removeAt(index);
    state = state.copyWith(crewMembers: updated);
  }

  void updateCrewMember(int index, CrewMember member) {
    final updated = [...state.crewMembers];
    updated[index] = member;
    state = state.copyWith(crewMembers: updated);
  }

  void reset() => state = FlightFormState();
}

final flightFormProvider =
    NotifierProvider<FlightFormNotifier, FlightFormState>(
      FlightFormNotifier.new,
    );
