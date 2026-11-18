import '../services/database.dart';

/// EASA logbook "pilot function time" column.
enum PilotFunction { pic, coPilot, dual, instructor }

/// How a flight is logged in the EASA logbook, given SELF's role and crew
/// (AMC1 FCL.050(b) and (i)(8)).
class LogbookFunction {
  const LogbookFunction({required this.function, this.picPerson});

  final PilotFunction function;

  /// The crew member whose surname goes in the PIC NAME column, or null when
  /// SELF is the PIC (the name then comes from settings: SELF or own name).
  final Person? picPerson;

  /// [proficiencyCheck]: the flight is a skill test or proficiency check
  /// passed with an examiner on board.
  static LogbookFunction resolve(
    CrewRole selfRole,
    List<CrewMember> crew, {
    bool proficiencyCheck = false,
  }) {
    Person? single(CrewRole role) {
      final matches = crew.where((m) => m.role == role).toList();
      return matches.length == 1 ? matches.first.person : null;
    }

    switch (selfRole) {
      case CrewRole.dual:
        final examiner = single(CrewRole.exm);
        // AMC1 FCL.050(b)(1)(ii): the flight time of a skill test or
        // proficiency check passed is logged as PIC, countersigned by the
        // examiner, who is named in the PIC column.
        if (proficiencyCheck && examiner != null) {
          return LogbookFunction(
            function: PilotFunction.pic,
            picPerson: examiner,
          );
        }
        // An examiner on board takes precedence over the instructor.
        return LogbookFunction(
          function: PilotFunction.dual,
          picPerson: examiner ?? single(CrewRole.ins),
        );
      case CrewRole.ins:
        return const LogbookFunction(function: PilotFunction.instructor);
      case CrewRole.sic:
      // AMC1 FCL.050(b)(3): a cruise relief co-pilot logs co-pilot time.
      case CrewRole.crcp:
        return LogbookFunction(
          function: PilotFunction.coPilot,
          picPerson: single(CrewRole.pic),
        );
      // AMC1 FCL.050(h), (i)(8): PICUS and SPIC time is logged as PIC, and
      // certified by the aircraft PIC or the instructor, who is the PIC.
      case CrewRole.picus:
        return LogbookFunction(
          function: PilotFunction.pic,
          picPerson: single(CrewRole.pic),
        );
      case CrewRole.spic:
        return LogbookFunction(
          function: PilotFunction.pic,
          picPerson: single(CrewRole.ins) ?? single(CrewRole.pic),
        );
      default:
        return const LogbookFunction(function: PilotFunction.pic);
    }
  }
}

/// Returns a user-facing error if the crew is inconsistent with SELF's role
/// (so the flight could not be logged unambiguously), or null if valid.
String? crewValidationError(CrewRole selfRole, List<CrewMember> crew) {
  int count(CrewRole role) => crew.where((m) => m.role == role).length;

  switch (selfRole) {
    case CrewRole.pic:
    case CrewRole.ins:
      if (count(CrewRole.pic) > 0) {
        return 'You are the PIC: no other crew member can be PIC.';
      }
    case CrewRole.dual:
      final ins = count(CrewRole.ins);
      final exm = count(CrewRole.exm);
      if (ins == 0 && exm == 0) {
        return 'Dual flights need an Instructor or an Examiner in the crew.';
      }
      if (ins > 1) return 'Dual flights must have only one Instructor.';
      if (exm > 1) return 'Dual flights must have only one Examiner.';
    case CrewRole.sic:
      final pic = count(CrewRole.pic);
      if (pic == 0) return 'As Second in Command you need a PIC in the crew.';
      if (pic > 1) return 'Only one crew member can be PIC.';
    case CrewRole.crcp:
      final pic = count(CrewRole.pic);
      if (pic == 0) {
        return 'As Cruise Relief Co-Pilot you need a PIC in the crew.';
      }
      if (pic > 1) return 'Only one crew member can be PIC.';
    // The PIC (or the instructor) countersigns PICUS and SPIC time: they
    // have to be in the crew to be named in the logbook.
    case CrewRole.picus:
      final pic = count(CrewRole.pic);
      if (pic == 0) return 'PICUS time needs the PIC in the crew.';
      if (pic > 1) return 'Only one crew member can be PIC.';
    case CrewRole.spic:
      if (count(CrewRole.ins) + count(CrewRole.pic) == 0) {
        return 'SPIC time needs the instructor in the crew.';
      }
      if (count(CrewRole.ins) > 1) {
        return 'Only one crew member can be Instructor.';
      }
    default:
      break;
  }
  return null;
}
