import '../services/database.dart';

/// EASA logbook "pilot function time" column.
enum PilotFunction { pic, coPilot, dual, instructor }

/// How a flight is logged in the EASA logbook, given SELF's role and crew.
class LogbookFunction {
  const LogbookFunction({required this.function, this.picPerson});

  final PilotFunction function;

  /// The crew member whose surname goes in the PIC NAME column, or null when
  /// SELF is the PIC (the name then comes from settings: SELF or own name).
  final Person? picPerson;

  static LogbookFunction resolve(CrewRole selfRole, List<CrewMember> crew) {
    Person? single(CrewRole role) {
      final matches = crew.where((m) => m.role == role).toList();
      return matches.length == 1 ? matches.first.person : null;
    }

    switch (selfRole) {
      case CrewRole.dual:
        // An examiner on board takes precedence over the instructor.
        return LogbookFunction(
          function: PilotFunction.dual,
          picPerson: single(CrewRole.exm) ?? single(CrewRole.ins),
        );
      case CrewRole.ins:
        return const LogbookFunction(function: PilotFunction.instructor);
      case CrewRole.sic:
        return LogbookFunction(
          function: PilotFunction.coPilot,
          picPerson: single(CrewRole.pic),
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
    default:
      break;
  }
  return null;
}
