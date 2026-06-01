class AirportFrequency {
  final String id;
  final String airportRef;
  final String airportIdent;
  final String type;
  final String description;
  final double frequencyMhz;

  const AirportFrequency({
    required this.id,
    required this.airportRef,
    required this.airportIdent,
    required this.type,
    required this.description,
    required this.frequencyMhz,
  });
}
