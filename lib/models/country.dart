class Country {
  final String id;
  final String code;
  final String name;
  final String continent;
  final String? wikipediaLink;
  final String? keywords;

  const Country({
    required this.id,
    required this.code,
    required this.name,
    required this.continent,
    this.wikipediaLink,
    this.keywords,
  });
}
