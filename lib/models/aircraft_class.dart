// The pilot rating an aircraft is flown under, used to count flights towards
// class and type rating currency.
//
// Follows EASA Part-FCL as published in the "EASA Class and Type Rating &
// Licence Endorsement List - Aeroplanes" (edition of 12.02.2026) and its
// explanatory notes:
//  * the aeroplane class ratings are TMG, SEP (land/sea), SET (land/sea) and
//    MEP (land/sea). SET is a single class since 2025; before that each
//    manufacturer had its own ("Cessna SET", "TBM SET"...);
//  * a "SEP aeroplane" may also have an electric or hybrid engine
//    (Regulation (EU) No 1178/2011, Article 2(8c));
//  * every other aeroplane (all jets, all multi-engine turboprops, multi-pilot
//    aeroplanes), every helicopter, powered-lift aircraft and airship needs
//    its own type rating.
// Sailplanes and balloons are licensed under Part-SFCL and Part-BFCL.
//
// Values are stored by name in the database (textEnum), so value names are
// part of the schema: don't rename them without a migration.

import 'aircraft_type_enums.dart';

enum AircraftClass {
  sepLand('SEP (land)', 'Single-engine piston, land'),
  sepSea('SEP (sea)', 'Single-engine piston, sea'),
  mepLand('MEP (land)', 'Multi-engine piston, land'),
  mepSea('MEP (sea)', 'Multi-engine piston, sea'),
  setLand('SET (land)', 'Single-engine turboprop, land'),
  setSea('SET (sea)', 'Single-engine turboprop, sea'),
  tmg('TMG', 'Touring motor glider'),

  /// Not part of any class: flown on its own type rating. The rating itself
  /// (e.g. "A320") is kept next to the class, in `Aircrafts.typeRating`.
  type('Type rating', 'Flown on its own type rating'),
  sailplane('Sailplane', 'Sailplanes and powered sailplanes (Part-SFCL)'),
  balloon('Balloon', 'Balloons and hot-air airships (Part-BFCL)'),

  /// Outside the EASA licences: ultralights, gyroplanes and other aircraft
  /// flown under national rules.
  other('Other', 'National rules: ultralight, gyroplane…');

  const AircraftClass(this.label, this.description);

  /// Short name, as endorsed on a licence where there is such an endorsement.
  final String label;
  final String description;

  /// The aeroplane class ratings of Part-FCL.
  static const classRatings = [
    sepLand,
    sepSea,
    mepLand,
    mepSea,
    setLand,
    setSea,
    tmg,
  ];

  /// Classes that are neither a class rating nor a type rating.
  static const nonPartFcl = [sailplane, balloon, other];

  bool get isClassRating => classRatings.contains(this);

  /// Every class an aircraft with these characteristics can be flown under,
  /// most likely first. Empty when nothing can be told (unknown type, engine
  /// data missing, more than one electric engine...).
  ///
  /// More than one result means the choice depends on something the type
  /// data doesn't say: an amphibian is "land" or "sea" depending on where it
  /// is operated, a motor glider is a TMG only if its engine and propeller
  /// don't retract.
  static List<AircraftClass> candidatesFor({
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) {
    switch (description) {
      case AircraftDescription.landplane:
        return _aeroplane(engineCount, engineType, land: true, sea: false);
      case AircraftDescription.seaplane:
        return _aeroplane(engineCount, engineType, land: false, sea: true);
      case AircraftDescription.amphibian:
        return _aeroplane(engineCount, engineType, land: true, sea: true);
      case AircraftDescription.helicopter:
      case AircraftDescription.tiltrotor:
      case AircraftDescription.airship:
        return const [type];
      case AircraftDescription.glider:
      case AircraftDescription.sailplane:
        return const [sailplane];
      case AircraftDescription.motorglider:
        return const [tmg, sailplane];
      case AircraftDescription.balloon:
        return const [balloon];
      case AircraftDescription.gyrocopter:
      case AircraftDescription.microlightAutogyro:
      case AircraftDescription.microlightHelicopter:
      case AircraftDescription.paraplane:
      case AircraftDescription.ultralightAircraft:
      case AircraftDescription.ultralightAutogyro:
      case AircraftDescription.ultralightHelicopter:
        return const [other];
      case AircraftDescription.unsupported:
        return const [];
    }
  }

  /// The class of an aircraft with these characteristics, or null when it
  /// can't be told or when there is more than one candidate.
  static AircraftClass? deduce({
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) {
    final candidates = candidatesFor(
      description: description,
      engineCount: engineCount,
      engineType: engineType,
    );
    return candidates.length == 1 ? candidates.single : null;
  }

  static List<AircraftClass> _aeroplane(
    int engineCount,
    EngineType engineType, {
    required bool land,
    required bool sea,
  }) {
    if (engineCount < 1) return const [];
    final single = engineCount == 1;
    List<AircraftClass> surfaces(AircraftClass onLand, AircraftClass onSea) => [
      if (land) onLand,
      if (sea) onSea,
    ];
    switch (engineType) {
      case EngineType.piston:
        return single ? surfaces(sepLand, sepSea) : surfaces(mepLand, mepSea);
      case EngineType.electric:
        // Several electric engines can still make a "SEP aeroplane", but
        // only when the aircraft is certified that way.
        return single ? surfaces(sepLand, sepSea) : const [];
      case EngineType.turboprop:
        return single ? surfaces(setLand, setSea) : const [type];
      case EngineType.jet:
        return const [type];
      case EngineType.rocket:
      case EngineType.none:
        return const [];
    }
  }
}
