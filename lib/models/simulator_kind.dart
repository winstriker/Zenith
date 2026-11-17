// The kinds of flight simulation training device (FSTD) a session can be
// flown in.
//
// From the definitions of Part-FCL (FCL.010 and GM1 FCL.010, Easy Access
// Rules, August 2020 edition) and the qualification levels of CS-FSTD:
//  * FFS: full flight simulator, a full size replica of a specific type with
//    a visual and a motion system. Levels A to D;
//  * FTD: flight training device, a replica of a type's flight deck without
//    the motion or (for aeroplanes) visual system. Levels 1 to 3;
//  * FNPT: flight and navigation procedures trainer, representing a type or
//    a class. Levels I to III, MCC when qualified for multi-crew training;
//  * BITD: basic instrument training device, for basic instrument flight
//    training only.
//
// Values are stored by name in the database (textEnum): don't rename them
// without a migration.

enum SimulatorKind {
  ffs('FFS', 'Full flight simulator', ['A', 'B', 'C', 'D']),
  ftd('FTD', 'Flight training device', ['1', '2', '3']),
  fnpt('FNPT', 'Flight and navigation procedures trainer', [
    'I',
    'II',
    'III',
    'II MCC',
    'III MCC',
  ]),
  bitd('BITD', 'Basic instrument training device', []),

  /// Any other device: not qualified, or qualified under national rules.
  other('Other', 'Other training device', []);

  const SimulatorKind(this.label, this.description, this.levels);

  final String label;
  final String description;

  /// The qualification levels a device of this kind can have, lowest first.
  final List<String> levels;

  /// FCL.060(b): take-offs and landings count for recent experience only in
  /// an aircraft "or an FFS representing that type or class".
  bool get countsForRecency => this == ffs;

  /// Devices a proficiency check can be passed in: the FSTDs of Part-FCL.
  /// A BITD is only for basic instrument training.
  bool get allowsProficiencyCheck => this == ffs || this == ftd || this == fnpt;

  /// AMC1 FCL.050(i)(9)(i): an FFS or FTD is entered in the logbook by the
  /// type it represents and its qualification number; other devices by their
  /// kind ("FNPT II").
  bool get loggedByType => this == ffs || this == ftd;

  /// The device's kind with its [level], as written on its qualification:
  /// "FFS D", "FNPT II MCC".
  String withLevel(String? level) {
    final l = level?.trim() ?? '';
    return l.isEmpty ? label : '$label $l';
  }
}
