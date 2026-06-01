class Airport {
  final String id;
  final String ident;
  final String type;
  final String name;
  final double? latitudeDeg;
  final double? longitudeDeg;
  final double? elevationFt;
  final String? continent;
  final String? isoCountry;
  final String? isoRegion;
  final String? municipality;
  final bool scheduledService;
  final String? icaoCode;
  final String? iataCode;
  final String? gpsCode;
  final String? localCode;
  final String? homeLink;
  final String? wikipediaLink;
  final String? keywords;

  const Airport({
    required this.id,
    required this.ident,
    required this.type,
    required this.name,
    this.latitudeDeg,
    this.longitudeDeg,
    this.elevationFt,
    this.continent,
    this.isoCountry,
    this.isoRegion,
    this.municipality,
    this.scheduledService = false,
    this.icaoCode,
    this.iataCode,
    this.gpsCode,
    this.localCode,
    this.homeLink,
    this.wikipediaLink,
    this.keywords,
  });

  String get displayCode => iataCode ?? icaoCode ?? (gpsCode ?? ident);

  String get typeLabel {
    switch (type) {
      case 'large_airport':
        return 'Large Airport';
      case 'medium_airport':
        return 'Medium Airport';
      case 'small_airport':
        return 'Small Airport';
      case 'heliport':
        return 'Heliport';
      case 'seaplane_base':
        return 'Seaplane Base';
      case 'closed':
        return 'Closed';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
