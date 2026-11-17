/// Segmented text search shared by the list pages.
///
/// A query is split into words, and an item matches when every word is found
/// in at least one of its fields, so "LIMC D-KBFF" finds a flight departing
/// LIMC flown with D-KBFF. Matching is case-insensitive and by substring.
///
/// The match runs in SQL so it composes with the paged lists: a page holds
/// the next matching rows, not the next rows that happen to match.
library;

import 'package:drift/drift.dart';

/// Lowercase words of [query]; empty when the query is blank.
List<String> searchTokens(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

/// Whether every token in [tokens] occurs in at least one of [fields].
/// Null fields never match; no tokens matches everything.
///
/// Case-insensitive for the English alphabet only, like SQLite's `LIKE`.
Expression<bool> sqlMatchesAllTokens(
  List<String> tokens,
  List<Expression<String>> fields,
) {
  if (tokens.isEmpty) return const Constant(true);
  return Expression.and([
    for (final token in tokens)
      Expression.or([
        for (final field in fields)
          field.like('%${_escapeLike(token)}%', escapeChar: r'\'),
      ]),
  ]);
}

/// [text] with the `LIKE` wildcards taken literally.
String _escapeLike(String text) =>
    text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
