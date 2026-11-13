// Enums describing an ICAO aircraft type (ICAO Doc 8643).
//
// Values are stored by name in the database (textEnum), so value names are
// part of the schema: don't rename them without a migration.

/// Z is a fallback for aircrafts without wake category like sailplanes
enum WakeTurbulenceCategory { J, H, L, M, Z }

/// Z is a fallback for aircrafts without wake group like sailplanes
enum WakeTurbulenceGroup { A, B, C, D, E, F, G, Z }

enum EngineType { electric, jet, piston, rocket, turboprop, none }

enum AircraftDescription {
  amphibian,
  gyrocopter,
  helicopter,
  landplane,
  seaplane,
  tiltrotor,
  airship,
  balloon,
  glider,
  motorglider,
  microlightAutogyro,
  microlightHelicopter,
  paraplane,
  sailplane,
  ultralightAircraft,
  ultralightAutogyro,
  ultralightHelicopter,
  unsupported,
}
