enum CrewRole {
  pic,
  picus,
  sic,

  /// Cruise relief co-pilot (AMC1 FCL.050(b)(3)): logs co-pilot time while
  /// occupying a pilot's seat, with 'CRCP' in the remarks.
  crcp,
  dual,
  spic,
  ins,
  exm,
  p3,
  sp,
  att,
  oth;

  String get abbreviation {
    switch (this) {
      case CrewRole.pic:
        return 'PIC';
      case CrewRole.picus:
        return 'PICUS';
      case CrewRole.sic:
        return 'SIC';
      case CrewRole.crcp:
        return 'CRCP';
      case CrewRole.dual:
        return 'DUAL';
      case CrewRole.spic:
        return 'SPIC';
      case CrewRole.ins:
        return 'INS';
      case CrewRole.exm:
        return 'EXM';
      case CrewRole.p3:
        return 'P3';
      case CrewRole.sp:
        return 'SP';
      case CrewRole.att:
        return 'ATT';
      case CrewRole.oth:
        return 'OTH';
    }
  }

  String get displayName {
    switch (this) {
      case CrewRole.pic:
        return 'Pilot in Command';
      case CrewRole.picus:
        return 'PIC under Supervision';
      case CrewRole.sic:
        return 'Second in Command';
      case CrewRole.crcp:
        return 'Cruise Relief Co-Pilot';
      case CrewRole.dual:
        return 'Dual received';
      case CrewRole.spic:
        return 'Student PIC';
      case CrewRole.ins:
        return 'Instructor';
      case CrewRole.exm:
        return 'Examiner';
      case CrewRole.p3:
        return 'Third Pilot';
      case CrewRole.sp:
        return 'Safety Pilot';
      case CrewRole.att:
        return 'Flight attendant';
      case CrewRole.oth:
        return 'Other';
    }
  }

  String? get subtitle {
    switch (this) {
      case CrewRole.picus:
        return 'PICUS, P1S, PF with fATPL';
      case CrewRole.sic:
        return 'Co-Pilot, First Officer, P2';
      case CrewRole.crcp:
        return 'In cruise, logs co-pilot time';
      case CrewRole.dual:
        return 'Pilot in Training (with Instructor)';
      case CrewRole.spic:
        return 'Solo flight in Training';
      case CrewRole.ins:
        return 'Dual given';
      case CrewRole.p3:
        return 'Junior Officer, P2X';
      default:
        return null;
    }
  }

  static CrewRole fromString(String value) {
    return CrewRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => CrewRole.pic,
    );
  }
}
