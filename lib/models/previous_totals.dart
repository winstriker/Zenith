import 'dart:convert';

import 'package:drift/drift.dart';

import 'logbook_overrides.dart';

/// What the pilot logged before using the app (a paper logbook, another
/// app): the totals carried forward into the first page of the exported
/// logbook, and the starting point of the app's own totals.
class PreviousTotals {
  const PreviousTotals({
    this.times = const {},
    this.dayLandings = 0,
    this.nightLandings = 0,
  });

  /// Unknown fields are dropped rather than failing the whole value.
  factory PreviousTotals.fromJson(Map<String, Object?> json) {
    final fields = LogbookTimeField.values.asNameMap();
    final times = <LogbookTimeField, Duration>{};
    if (json['times'] case final Map<String, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        final field = fields[key];
        if (field != null && value is int && value > 0) {
          times[field] = Duration(minutes: value);
        }
      }
    }
    int count(String key) => switch (json[key]) {
      final int n when n > 0 => n,
      _ => 0,
    };
    return PreviousTotals(
      times: times,
      dayLandings: count('dayLandings'),
      nightLandings: count('nightLandings'),
    );
  }

  /// Only the columns with time in them.
  final Map<LogbookTimeField, Duration> times;
  final int dayLandings;
  final int nightLandings;

  static const empty = PreviousTotals();

  Duration time(LogbookTimeField field) => times[field] ?? Duration.zero;

  bool get isEmpty => times.isEmpty && dayLandings == 0 && nightLandings == 0;
  bool get isNotEmpty => !isEmpty;

  /// A copy with [field] set to [value]; null or zero clears it.
  PreviousTotals withTime(LogbookTimeField field, Duration? value) {
    final updated = {...times};
    if (value == null || value <= Duration.zero) {
      updated.remove(field);
    } else {
      updated[field] = value;
    }
    return PreviousTotals(
      times: updated,
      dayLandings: dayLandings,
      nightLandings: nightLandings,
    );
  }

  PreviousTotals withLandings({int? day, int? night}) => PreviousTotals(
    times: times,
    dayLandings: day ?? dayLandings,
    nightLandings: night ?? nightLandings,
  );

  Map<String, Object?> toJson() => {
    if (times.isNotEmpty)
      'times': {
        for (final MapEntry(:key, :value) in times.entries)
          key.name: value.inMinutes,
      },
    if (dayLandings > 0) 'dayLandings': dayLandings,
    if (nightLandings > 0) 'nightLandings': nightLandings,
  };

  /// Stores the totals as JSON in a text column.
  static const converter = _PreviousTotalsConverter();

  @override
  bool operator ==(Object other) =>
      other is PreviousTotals &&
      other.dayLandings == dayLandings &&
      other.nightLandings == nightLandings &&
      other.times.length == times.length &&
      times.entries.every((e) => other.times[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    dayLandings,
    nightLandings,
    Object.hashAllUnordered(
      times.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

class _PreviousTotalsConverter extends TypeConverter<PreviousTotals, String> {
  const _PreviousTotalsConverter();

  @override
  PreviousTotals fromSql(String fromDb) {
    try {
      return PreviousTotals.fromJson(
        (jsonDecode(fromDb) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return PreviousTotals.empty;
    }
  }

  @override
  String toSql(PreviousTotals value) => jsonEncode(value.toJson());
}
