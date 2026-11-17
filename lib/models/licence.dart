// Pilot licences, the ratings and certificates endorsed on them, and medical
// certificates.
//
// Follows EASA Part-FCL (Easy Access Rules, August 2020 edition). Only the
// handful of categories the currency logic depends on are built in; anything
// that changes over time (type rating endorsements, instructor certificate
// names...) is typed in by the pilot.
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
  balloon('B', 'Balloon');

  const AircraftCategory(this.suffix, this.label);

  final String suffix;
  final String label;
}

/// A rating, endorsement or certificate written on a licence.
enum RatingKind {
  classRating('Class rating'),
  typeRating('Type rating'),
  instrument('Instrument rating (IR)'),
  enRouteInstrument('En route instrument rating (EIR)'),
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
    instructor,
    examiner,
    languageProficiency,
    towing,
    other,
  ].contains(this);

  /// What to call the name field.
  String get nameLabel => switch (this) {
    typeRating => 'Type rating endorsement',
    instructor => 'Certificate',
    examiner => 'Certificate',
    languageProficiency => 'Language',
    towing => 'Towing',
    _ => 'Name',
  };

  String? get nameHint => switch (this) {
    typeRating => 'e.g. A320, B737 300-900, R44',
    instructor => 'e.g. FI(A), CRI(A), TRI(A)',
    examiner => 'e.g. FE(A), CRE',
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
    // FCL.625(a), FCL.825(g)(1), FCL.835(g)(1).
    instrument || enRouteInstrument || basicInstrument => 12,
    // FCL.815(d).
    mountain => 24,
    // FCL.940, FCL.1025(a): 3 years.
    instructor || examiner => 36,
    // FCL.055(c): depends on the level.
    languageProficiency => null,
    night || aerobatic || towing || flightTest || other => null,
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
    instrument => 'FCL.625',
    enRouteInstrument => 'FCL.825',
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
