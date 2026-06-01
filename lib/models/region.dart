class Region {
  final String id;
  final String code;
  final String localCode;
  final String name;
  final String continent;
  final String isoCountry;
  final String? wikipediaLink;
  final String? keywords;

  const Region({
    required this.id,
    required this.code,
    required this.localCode,
    required this.name,
    required this.continent,
    required this.isoCountry,
    this.wikipediaLink,
    this.keywords,
  });
}
