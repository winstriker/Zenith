class Runway {
  final String id;
  final String airportRef;
  final String airportIdent;
  final double? lengthFt;
  final double? widthFt;
  final String? surface;
  final bool lighted;
  final bool closed;
  final String? leIdent;
  final double? leLatitudeDeg;
  final double? leLongitudeDeg;
  final double? leElevationFt;
  final double? leHeadingDegT;
  final double? leDisplacedThresholdFt;
  final String? heIdent;
  final double? heLatitudeDeg;
  final double? heLongitudeDeg;
  final double? heElevationFt;
  final double? heHeadingDegT;
  final double? heDisplacedThresholdFt;

  const Runway({
    required this.id,
    required this.airportRef,
    required this.airportIdent,
    this.lengthFt,
    this.widthFt,
    this.surface,
    this.lighted = false,
    this.closed = false,
    this.leIdent,
    this.leLatitudeDeg,
    this.leLongitudeDeg,
    this.leElevationFt,
    this.leHeadingDegT,
    this.leDisplacedThresholdFt,
    this.heIdent,
    this.heLatitudeDeg,
    this.heLongitudeDeg,
    this.heElevationFt,
    this.heHeadingDegT,
    this.heDisplacedThresholdFt,
  });
}
