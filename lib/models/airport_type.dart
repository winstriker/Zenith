/// Airport category, as defined by the OurAirports dataset.
enum AirportType {
  undefined,
  closed,
  smallAirport,
  mediumAirport,
  largeAirport,
  heliport,
  balloonport,
  seaplaneBase;

  static AirportType fromCsvString(String str) {
    switch (str) {
      case "small_airport":
        return AirportType.smallAirport;
      case "medium_airport":
        return AirportType.mediumAirport;
      case "large_airport":
        return AirportType.largeAirport;
      case "balloonport":
        return AirportType.balloonport;
      case "heliport":
        return AirportType.heliport;
      case "seaplane_base":
        return AirportType.seaplaneBase;
      case "closed":
        return AirportType.closed;
      default:
        return AirportType.undefined;
    }
  }

  static String getDisplayName(AirportType type) {
    switch (type) {
      case AirportType.smallAirport:
        return "Small Airport";
      case AirportType.mediumAirport:
        return "Medium Airport";
      case AirportType.largeAirport:
        return "Large Airport";
      case AirportType.balloonport:
        return "Balloonport";
      case AirportType.heliport:
        return "Heliport";
      case AirportType.seaplaneBase:
        return "Seaplane Base";
      case AirportType.closed:
        return "Closed";
      case AirportType.undefined:
        return "Undefined";
    }
  }
}
