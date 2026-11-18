// Pilot licences, the ratings and certificates endorsed on them, and medical
// certificates.
//
// Follows EASA Part-FCL (Easy Access Rules for Aircrew, October 2026
// edition: Regulation (EU) No 1178/2011 up to Implementing Regulation (EU)
// 2026/781). Only the handful of categories the currency logic depends on are
// built in; anything that changes over time (type rating endorsements,
// instructor certificate names...) is typed in by the pilot.
//
// Values are stored by name in the database (textEnum), so value names are
// part of the schema: don't rename them without a migration.

import 'aircraft_class.dart';

/// The licence itself.
enum LicenceKind {
  lapl('LAPL', 'Light aircraft pilot licence'),
  ppl('PPL', 'Private pilot licence'),
  cpl('CPL', 'Commercial pilot licence'),
  mpl('MPL', 'Multi-crew pilot licence'),
  atpl('ATPL', 'Airline transport pilot licence'),
  spl('SPL', 'Sailplane pilot licence'),
  bpl('BPL', 'Balloon pilot licence'),

  /// Gyroplane pilot licence (FCL.205.G, Regulation (EU) 2025/134).
  gpl('GPL', 'Gyroplane pilot licence'),

  /// A licence outside Part-FCL: national, FAA, ultralight...
  other('Other', 'National or non-EASA licence');

  const LicenceKind(this.label, this.description);

  final String label;
  final String description;

  /// Aircraft categories a licence of this kind can be issued for.
  List<AircraftCategory> get categories => switch (this) {
    lapl => const [AircraftCategory.aeroplane, AircraftCategory.helicopter],
    ppl || cpl || atpl => const [
      AircraftCategory.aeroplane,
      AircraftCategory.helicopter,
      AircraftCategory.poweredLift,
      AircraftCategory.airship,
    ],
    mpl => const [AircraftCategory.aeroplane],
    spl => const [AircraftCategory.sailplane],
    bpl => const [AircraftCategory.balloon],
    gpl => const [AircraftCategory.gyroplane],
    other => AircraftCategory.values,
  };

  /// Whether night flying is part of the licence privileges. A PPL or LAPL
  /// needs a night rating for it.
  bool get includesNight => this == cpl || this == mpl || this == atpl;
}

/// The aircraft category of a licence, shown after its name: PPL(A).
enum AircraftCategory {
  aeroplane('A', 'Aeroplane'),
  helicopter('H', 'Helicopter'),
  poweredLift('PL', 'Powered-lift'),
  airship('As', 'Airship'),
  sailplane('S', 'Sailplane'),
  balloon('B', 'Balloon'),
  gyroplane('G', 'Gyroplane');

  const AircraftCategory(this.suffix, this.label);

  final String suffix;
  final String label;
}

/// A rating, endorsement or certificate written on a licence.
enum RatingKind {
  classRating('Class rating'),
  typeRating('Type rating'),

  /// Type rating for a VTOL-capable aircraft (VCA), held with a CPL(A) or
  /// CPL(H) (Article 4f of Regulation (EU) No 1178/2011).
  vcaTypeRating('VCA type rating'),
  instrument('Instrument rating (IR)'),

  // The en route instrument rating (EIR, FCL.825) is gone: its holders could
  // use it until 8 September 2022 (Article 4c).
  basicInstrument('Basic instrument rating (BIR)'),
  night('Night rating'),
  mountain('Mountain rating'),
  aerobatic('Aerobatic rating'),
  towing('Towing rating'),
  flightTest('Flight test rating'),
  instructor('Instructor certificate'),
  examiner('Examiner certificate'),
  languageProficiency('Language proficiency'),
  other('Other');

  const RatingKind(this.label);

  final String label;

  /// Whether the pilot types the name of the rating (an aircraft type, a
  /// certificate, a language).
  bool get hasName => const [
    typeRating,
    vcaTypeRating,
    instructor,
    examiner,
    languageProficiency,
    towing,
    other,
  ].contains(this);

  /// What to call the name field.
  String get nameLabel => switch (this) {
    typeRating || vcaTypeRating => 'Type rating endorsement',
    instructor => 'Certificate',
    examiner => 'Certificate',
    languageProficiency => 'Language',
    towing => 'Towing',
    _ => 'Name',
  };

  String? get nameHint => switch (this) {
    typeRating => 'e.g. A320, B737 300-900, R44',
    vcaTypeRating => 'As endorsed on the licence',
    instructor => 'e.g. FI(A), CRI(A), TRI(H), FI(G)',
    examiner => 'e.g. FE(A), CRE, FE(G)',
    languageProficiency => 'e.g. English',
    towing => 'Sailplane or banner',
    _ => null,
  };

  /// How long the rating is valid for from its issue or revalidation, in
  /// months, as Part-FCL sets it. Null when it doesn't expire, or when it
  /// depends on details the kind alone doesn't tell (see [validityFor]).
  int? get defaultValidityMonths => switch (this) {
    // FCL.740(a): 1 year, 2 for single-pilot single-engine class ratings.
    classRating => null,
    typeRating => 12,
    // Article 4f(5).
    vcaTypeRating => 12,
    // FCL.625(a), FCL.835(g)(1).
    instrument || basicInstrument => 12,
    // FCL.940, FCL.1025(a): 3 years.
    instructor || examiner => 36,
    // FCL.055(c): depends on the level.
    languageProficiency => null,
    // FCL.815(d): since Regulation (EU) 2024/2076 the mountain rating
    // doesn't expire any more. Its privileges need recent landings or a
    // check instead (see the currency rules).
    mountain || night || aerobatic || towing || flightTest || other => null,
  };

  /// The validity of a rating of this kind, in months: see
  /// [defaultValidityMonths]. Null when it doesn't expire.
  int? validityFor({AircraftClass? aircraftClass, int? level}) =>
      switch (this) {
        classRating => switch (aircraftClass) {
          AircraftClass.mepLand || AircraftClass.mepSea => 12,
          null => null,
          _ => 24,
        },
        languageProficiency => switch (level) {
          4 => 48,
          5 => 72,
          _ => null,
        },
        _ => defaultValidityMonths,
      };

  /// The rule the validity comes from.
  String? get reference => switch (this) {
    classRating || typeRating => 'FCL.740',
    vcaTypeRating => 'Article 4f',
    instrument => 'FCL.625',
    basicInstrument => 'FCL.835',
    mountain => 'FCL.815',
    instructor => 'FCL.940',
    examiner => 'FCL.1025',
    languageProficiency => 'FCL.055',
    _ => null,
  };
}

/// Medical certificate classes (Part-MED).
enum MedicalClass {
  class1('Class 1'),
  class2('Class 2'),
  lapl('LAPL'),
  other('Other');

  const MedicalClass(this.label);

  final String label;
}
