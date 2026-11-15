import '../services/database.dart';

/// The ICAO types that best fit a free-text aircraft name.
class IcaoTypeMatch {
  const IcaoTypeMatch({this.best, this.suggestions = const []});

  /// The type to use without asking, or null when no type stands out.
  final IcaoAircraft? best;

  /// Closest types, best first. Includes [best].
  final List<IcaoAircraft> suggestions;
}

/// Finds the ICAO type (Doc 8643) behind an aircraft name written the way
/// photo sites write it: "Cessna 172R Skyhawk II", "Boeing 737-8K2",
/// "Agusta-Westland AW-139".
///
/// Such names never equal an ICAO entry ("CESSNA" + "172 Skyhawk"), so every
/// type gets a score from how much of its model name is found, in order, in
/// the given name, plus a bonus when the manufacturer is recognised. A type
/// is only picked on its own ([IcaoTypeMatch.best]) when every type scoring
/// about as well shares its designator: picking the wrong variant of a C172
/// is harmless, picking a B38M for a B738 is not.
class IcaoTypeMatcher {
  IcaoTypeMatcher._();

  /// Lowest score for a type to be suggested at all.
  static const _minScore = 0.5;

  /// Lowest score for a type to be picked without asking.
  static const _minConfident = 0.7;

  /// Types within this distance of the best score count as equally good.
  static const _margin = 0.05;

  /// A type whose manufacturer is not in the name needs a model name that
  /// fits at least this well.
  static const _minWithoutManufacturer = 0.75;
  static const _manufacturerBonus = 0.15;

  /// Words in ICAO manufacturer names that don't identify anyone.
  static const _fillers = {
    'aircraft',
    'aviation',
    'industries',
    'helicopters',
    'helicopter',
    'company',
    'corporation',
    'aero',
    'aerospace',
    'international',
    'the',
  };

  static const _roman = {
    'i': '1',
    'ii': '2',
    'iii': '3',
    'iv': '4',
    'v': '5',
    'vi': '6',
  };

  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
    'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ß': 'ss',
  };

  // Boeing customer codes: a 737-8K2 is a 737-800, a 747-436 a 747-400.
  static final _boeingCustomer = RegExp(
    r'\b(7[0-8]7)-([1-9])[0-9a-z]{2}\b',
    caseSensitive: false,
  );

  // Airbus engine codes ending in N: an A320-271N is an A320neo.
  static final _airbusNeo = RegExp(
    r'\b(A3[1-3][0-9])-[0-9]{3}N[XY]?\b',
    caseSensitive: false,
  );

  static final _separators = RegExp('[^a-z0-9]+');
  static final _runs = RegExp('[a-z]+|[0-9]+');
  static final _digits = RegExp(r'^[0-9]+$');

  /// Finds the type of an aircraft from what lookup services say about it:
  /// its ICAO [designator], when one knows it, and the [names] they call it.
  ///
  /// A designator settles the type; the names then only choose among the
  /// entries ICAO lists under it (CESSNA "172 Skyhawk" or REIMS "F172").
  /// Without a designator, or with one ICAO doesn't list, the names are
  /// matched against every type, see [match].
  static IcaoTypeMatch resolve({
    required String? designator,
    required List<String> names,
    required List<IcaoAircraft> types,
    int limit = 6,
  }) {
    final wanted = designator?.trim().toUpperCase() ?? '';
    final sameDesignator = wanted.isEmpty
        ? const <IcaoAircraft>[]
        : [
            for (final type in types)
              if (type.designator.toUpperCase() == wanted) type,
          ];
    if (sameDesignator.isNotEmpty) {
      final scores = <IcaoAircraft, double>{};
      for (final name in names) {
        for (final (score, type) in _rank(name, sameDesignator, 0)) {
          if (score > (scores[type] ?? -1)) scores[type] = score;
        }
      }
      // Best fitting name first; among equals, the plainest entry.
      final ranked = [...sameDesignator]
        ..sort((a, b) {
          final byScore = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
          return byScore != 0
              ? byScore
              : a.modelFullName.length.compareTo(b.modelFullName.length);
        });
      return IcaoTypeMatch(
        best: ranked.first,
        suggestions: ranked.take(limit).toList(),
      );
    }

    var fallback = const IcaoTypeMatch();
    for (final name in names) {
      final found = match(name, types, limit: limit);
      if (found.best != null) return found;
      if (fallback.suggestions.isEmpty) fallback = found;
    }
    return fallback;
  }

  static IcaoTypeMatch match(
    String name,
    List<IcaoAircraft> types, {
    int limit = 6,
  }) {
    final scored = _rank(name, types, _minScore);
    if (scored.isEmpty) return const IcaoTypeMatch();

    final top = scored.first.$1;
    final designators = {
      for (final (score, type) in scored)
        if (score >= top - _margin) type.designator,
    };
    return IcaoTypeMatch(
      best: top >= _minConfident && designators.length == 1
          ? scored.first.$2
          : null,
      suggestions: [for (final (_, type) in scored.take(limit)) type],
    );
  }

  /// The [types] that fit [name] with at least [minScore], best first.
  static List<(double, IcaoAircraft)> _rank(
    String name,
    List<IcaoAircraft> types,
    double minScore,
  ) {
    final spellings = [for (final s in _spellings(name)) _nameTokens(s)];
    if (spellings.every((s) => s.isEmpty)) return const [];

    final scored = <(double, IcaoAircraft)>[];
    for (final type in types) {
      final manufacturer = _tokens(
        type.manufacturer,
      ).where((t) => !_digits.hasMatch(t) && !_fillers.contains(t)).toList();
      final model = _atoms(_tokens(type.modelFullName));
      if (model.isEmpty) continue;
      var best = 0.0;
      for (final spelling in spellings) {
        final score = _score(spelling, manufacturer, model);
        if (score > best) best = score;
      }
      if (best >= minScore) scored.add((best, type));
    }
    return scored..sort((a, b) => b.$1.compareTo(a.$1));
  }

  /// The name as given, plus the same name with maker-specific variant codes
  /// rewritten the way ICAO lists them.
  static List<String> _spellings(String name) {
    final result = [name];
    final neo = _airbusNeo.firstMatch(name);
    if (neo != null) {
      result.add(name.replaceRange(neo.start, neo.end, '${neo.group(1)}neo'));
    }
    final boeing = _boeingCustomer.firstMatch(name);
    if (boeing != null && !boeing.group(0)!.endsWith('00')) {
      result.add(
        name.replaceRange(
          boeing.start,
          boeing.end,
          '${boeing.group(1)}-${boeing.group(2)}00',
        ),
      );
    }
    return result;
  }

  static double _score(
    List<String> name,
    List<String> manufacturer,
    List<String> model,
  ) {
    final (matched, rest) = _withoutManufacturer(name, manufacturer);
    final atoms = _atoms(rest);
    if (atoms.isEmpty) return 0;

    var fit =
        2 *
        _commonWeight(atoms, model) /
        (atoms.fold(0.0, (sum, a) => sum + _weight(a)) +
            model.fold(0.0, (sum, a) => sum + _weight(a)));

    // Same letters and digits spaced differently ("LongEZ" / "Long-EZ"), or
    // one name inside the other.
    final a = atoms.join();
    final b = model.join();
    final (short, long) = a.length <= b.length ? (a, b) : (b, a);
    if (short.length >= 4 && _containsWhole(long, short)) {
      final contained = 0.5 + 0.5 * short.length / long.length;
      if (contained > fit) fit = contained;
    }

    if (!matched && fit < _minWithoutManufacturer) return 0;
    return fit + (matched ? _manufacturerBonus : 0);
  }

  /// Whether [long] contains [short] without cutting a number in two
  /// ("falcon2000" does not contain "falcon200").
  static bool _containsWhole(String long, String short) {
    bool digit(int i) =>
        i >= 0 &&
        i < long.length &&
        long.codeUnitAt(i) >= 0x30 &&
        long.codeUnitAt(i) <= 0x39;
    var from = 0;
    while (true) {
      final at = long.indexOf(short, from);
      if (at < 0) return false;
      final end = at + short.length;
      final cutsBefore = digit(at) && digit(at - 1);
      final cutsAfter = digit(end - 1) && digit(end);
      if (!cutsBefore && !cutsAfter) return true;
      from = at + 1;
    }
  }

  /// Removes the manufacturer from [name]. Returns whether it was there.
  static (bool, List<String>) _withoutManufacturer(
    List<String> name,
    List<String> manufacturer,
  ) {
    if (manufacturer.isEmpty) return (false, name);

    // "Agusta-Westland" for AGUSTAWESTLAND: same letters, split differently.
    final compact = manufacturer.join();
    var read = 0;
    for (var i = 0; i < name.length; i++) {
      if (!compact.startsWith(name[i], read)) break;
      read += name[i].length;
      if (read == compact.length) return (true, name.sublist(i + 1));
    }

    // "Beechcraft" for BEECH, "Reims-Cessna" for REIMS.
    bool same(String a, String b) {
      if (a == b) return true;
      final (short, long) = a.length <= b.length ? (a, b) : (b, a);
      return short.length >= 4 && long.startsWith(short);
    }

    final words = manufacturer.where((m) => m.length >= 3);
    final rest = [
      for (final token in name)
        if (!words.any((m) => same(token, m))) token,
    ];
    return (rest.length != name.length, rest);
  }

  /// Total weight of the atoms [name] and [model] have in common, in the
  /// same order (a weighted longest common subsequence).
  static double _commonWeight(List<String> name, List<String> model) {
    var previous = List<double>.filled(model.length + 1, 0);
    for (final a in name) {
      final current = List<double>.filled(model.length + 1, 0);
      for (var j = 0; j < model.length; j++) {
        var best = previous[j + 1] > current[j] ? previous[j + 1] : current[j];
        final similarity = _similarity(a, model[j]);
        if (similarity > 0) {
          final taken = previous[j] + similarity * _weight(model[j]);
          if (taken > best) best = taken;
        }
        current[j + 1] = best;
      }
      previous = current;
    }
    return previous.last;
  }

  /// Numbers say more about a model than words do.
  static double _weight(String atom) {
    if (_digits.hasMatch(atom)) return atom.length >= 2 ? 3 : 1.5;
    return atom.length >= 3 ? 2 : 1;
  }

  static double _similarity(String a, String b) {
    if (a == b) return 1;
    // A round model number stands for its sub-variants (402 for 400), but
    // 172 is not a 175.
    if (a.length == b.length &&
        a.length >= 3 &&
        _digits.hasMatch(a) &&
        _digits.hasMatch(b) &&
        a.substring(0, a.length - 2) == b.substring(0, b.length - 2) &&
        (a.endsWith('00') || b.endsWith('00'))) {
      return 0.5;
    }
    return 0;
  }

  /// Lower-case words of [text], without accents or punctuation.
  static List<String> _tokens(String text) {
    final folded = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      folded.write(_accents[char] ?? char);
    }
    return folded
        .toString()
        .split(_separators)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// [_tokens] with roman numerals after the first word turned into digits,
  /// the way ICAO writes them ("Arrow III" is "Arrow 3").
  static List<String> _nameTokens(String name) {
    final tokens = _tokens(name);
    return [
      for (var i = 0; i < tokens.length; i++)
        i == 0 ? tokens[i] : _roman[tokens[i]] ?? tokens[i],
    ];
  }

  /// Splits words into runs of letters and runs of digits, so "M20F" and
  /// "M-20F" read the same.
  static List<String> _atoms(List<String> tokens) => [
    for (final token in tokens)
      for (final run in _runs.allMatches(token)) run.group(0)!,
  ];
}
