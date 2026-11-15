/// Segmented text search shared by the list pages.
///
/// A query is split into words, and an item matches when every word is found
/// in at least one of its fields, so "LIMC D-KBFF" finds a flight departing
/// LIMC flown with D-KBFF. Matching is case-insensitive and by substring.
library;

/// Lowercase words of [query]; empty when the query is blank.
List<String> searchTokens(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

/// Whether every token in [tokens] occurs in at least one of [fields].
/// Null fields are ignored; no tokens matches everything.
bool matchesAllTokens(List<String> tokens, Iterable<String?> fields) {
  final haystack = [
    for (final f in fields)
      if (f != null && f.isNotEmpty) f.toLowerCase(),
  ];
  return tokens.every((t) => haystack.any((f) => f.contains(t)));
}
