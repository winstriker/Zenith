import 'dart:convert';

import 'package:drift/drift.dart';

/// The time columns of the EASA logbook a flight fills in.
///
/// The names are stored (see [LogbookOverrides.toJson]): don't rename them.
enum LogbookTimeField {
  total('Total time'),
  singlePilotSe('Single-pilot SE'),
  singlePilotMe('Single-pilot ME'),
  multiPilot('Multi-pilot'),
  night('Night'),
  ifr('IFR'),
  pic('PIC'),
  coPilot('Co-pilot'),
  dual('Dual'),
  instructor('Instructor');

  const LogbookTimeField(this.label);
  final String label;
}

/// Values the pilot typed in for a flight's logbook line, replacing the ones
/// worked out from the flight. Only used in the exported logbook.
class LogbookOverrides {
  const LogbookOverrides({this.times = const {}, this.picName});

  /// Unknown fields are dropped rather than failing the whole flight.
  factory LogbookOverrides.fromJson(Map<String, Object?> json) {
    final fields = LogbookTimeField.values.asNameMap();
    final times = <LogbookTimeField, Duration>{};
    if (json['times'] case final Map<String, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        final field = fields[key];
        if (field != null && value is int) {
          times[field] = Duration(minutes: value);
        }
      }
    }
    return LogbookOverrides(times: times, picName: json['picName'] as String?);
  }

  final Map<LogbookTimeField, Duration> times;
  final String? picName;

  static const empty = LogbookOverrides();

  bool get isEmpty => times.isEmpty && picName == null;
  bool get isNotEmpty => !isEmpty;

  /// How many fields are overridden.
  int get count => times.length + (picName == null ? 0 : 1);

  /// A copy with [field] set to [value], or back to the computed value when
  /// [value] is null.
  LogbookOverrides withTime(LogbookTimeField field, Duration? value) {
    final updated = {...times};
    if (value == null) {
      updated.remove(field);
    } else {
      updated[field] = value;
    }
    return LogbookOverrides(times: updated, picName: picName);
  }

  LogbookOverrides withPicName(String? value) =>
      LogbookOverrides(times: times, picName: value);

  Map<String, Object?> toJson() => {
    if (times.isNotEmpty)
      'times': {
        for (final MapEntry(:key, :value) in times.entries)
          key.name: value.inMinutes,
      },
    'picName': ?picName,
  };

  /// Stores overrides as JSON in a text column.
  static const converter = _LogbookOverridesConverter();

  @override
  bool operator ==(Object other) =>
      other is LogbookOverrides &&
      other.picName == picName &&
      other.times.length == times.length &&
      times.entries.every((e) => other.times[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    picName,
    Object.hashAllUnordered(
      times.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

class _LogbookOverridesConverter
    extends TypeConverter<LogbookOverrides, String> {
  const _LogbookOverridesConverter();

  @override
  LogbookOverrides fromSql(String fromDb) {
    try {
      return LogbookOverrides.fromJson(
        (jsonDecode(fromDb) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return LogbookOverrides.empty;
    }
  }

  @override
  String toSql(LogbookOverrides value) => jsonEncode(value.toJson());
}
