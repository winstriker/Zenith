import '../services/database.dart';
import 'crew_rules.dart';

/// Flight rules as filed: anything other than plain VFR or IFR is a flight
/// that changes rules on the way (Y, Z, ...).
enum FlightRulesKind {
  vfr,
  ifr,
  mixed;

  static FlightRulesKind of(String? rules) => switch (rules) {
    null || 'VFR' => vfr,
    'IFR' => ifr,
    _ => mixed,
  };
}

/// One flight as a line of the EASA logbook: every column worked out from
/// the flight, with the pilot's [overrides] on top.
class LogbookEntry {
  LogbookEntry._({
    required this.computed,
    required this.overrides,
    required this.computedPicName,
    required this.remarks,
    required this.dayLandings,
    required this.nightLandings,
  });

  /// [selfPicName] goes in the PIC NAME column when the pilot is the PIC
  /// ("SELF" or their own name, as set in the settings).
  factory LogbookEntry.of(
    FlightWithStats flight, {
    List<CrewMember> crew = const [],
    String selfPicName = 'SELF',
    LogbookOverrides? overrides,
  }) {
    final f = flight.flight;
    final applied = overrides ?? f.logbookOverrides ?? LogbookOverrides.empty;
    final block = flight.duration;
    final blockTime = block == null || block.isNegative ? Duration.zero : block;

    // AMC1 FCL.050(i)(9): a session in an FSTD only fills in column 11, the
    // total time of the session. It isn't flight time: no aircraft, landings
    // or pilot function columns.
    if (flight.isSimulatorSession) {
      return LogbookEntry._(
        computed: {
          for (final field in LogbookTimeField.values) field: Duration.zero,
          LogbookTimeField.fstd: blockTime,
        },
        overrides: applied,
        computedPicName: '',
        remarks: f.remarks ?? '',
        dayLandings: 0,
        nightLandings: 0,
      );
    }

    // Everything below is a share of the flight's total time: an overridden
    // total moves them along, unless they're overridden as well.
    final total = applied.times[LogbookTimeField.total] ?? blockTime;
    Duration capped(Duration? d) =>
        d == null ? Duration.zero : (d > total ? total : d);

    final multiEngine = (flight.aircraftWithStats?.engineCount ?? 1) > 1;
    final selfRole = CrewRole.fromString(f.pilotRole ?? CrewRole.pic.name);
    final logbook = LogbookFunction.resolve(selfRole, crew);
    // A second in command on board (or being it) makes it a multi-pilot
    // flight: its time goes in that column instead of the single-pilot ones.
    final multiPilot = isMultiPilot(selfRole, crew);
    Duration singlePilot({required bool me}) =>
        !multiPilot && multiEngine == me ? total : Duration.zero;
    Duration function(PilotFunction fn) =>
        logbook.function == fn ? total : Duration.zero;

    final ifr = switch (FlightRulesKind.of(f.flightRules)) {
      FlightRulesKind.vfr => Duration.zero,
      FlightRulesKind.ifr => total,
      FlightRulesKind.mixed => capped(
        f.instrumentMinutes == null
            ? null
            : Duration(minutes: f.instrumentMinutes!),
      ),
    };

    return LogbookEntry._(
      computed: {
        LogbookTimeField.total: blockTime,
        LogbookTimeField.singlePilotSe: singlePilot(me: false),
        LogbookTimeField.singlePilotMe: singlePilot(me: true),
        LogbookTimeField.multiPilot: multiPilot ? total : Duration.zero,
        LogbookTimeField.night: capped(
          f.nightMinutes == null ? null : Duration(minutes: f.nightMinutes!),
        ),
        LogbookTimeField.ifr: ifr,
        // An instructor is the PIC as well: their time goes in both columns.
        LogbookTimeField.pic: logbook.function == PilotFunction.instructor
            ? total
            : function(PilotFunction.pic),
        LogbookTimeField.coPilot: function(PilotFunction.coPilot),
        LogbookTimeField.dual: function(PilotFunction.dual),
        LogbookTimeField.instructor: function(PilotFunction.instructor),
        LogbookTimeField.fstd: Duration.zero,
      },
      overrides: applied,
      computedPicName: logbook.picPerson?.surname ?? selfPicName,
      remarks: f.remarks ?? '',
      dayLandings: f.dayLandings ?? 0,
      nightLandings: f.nightLandings ?? 0,
    );
  }

  /// Whether a flight is logged as multi-pilot: when it has a second in
  /// command, the pilot or one of the crew.
  static bool isMultiPilot(CrewRole selfRole, List<CrewMember> crew) =>
      selfRole == CrewRole.sic || crew.any((m) => m.role == CrewRole.sic);

  /// Each column as worked out from the flight, before the overrides.
  final Map<LogbookTimeField, Duration> computed;
  final LogbookOverrides overrides;
  final String computedPicName;

  /// Remarks are logged as they are: they can't be overridden.
  final String remarks;

  /// Landings are logged as they are: they can't be overridden. None for a
  /// simulator session, whose landings only count for recent experience.
  final int dayLandings;
  final int nightLandings;

  Duration time(LogbookTimeField field) =>
      overrides.times[field] ?? computed[field]!;

  String get picName => overrides.picName ?? computedPicName;

  bool isOverridden(LogbookTimeField field) =>
      overrides.times.containsKey(field);
}
