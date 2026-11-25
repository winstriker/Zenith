import 'package:flutter/material.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart' as tz;

class TZDateTimeParser {
  static TimeOfDay parseTimeOfDay(String text) {
    final cleaned = text.replaceAll(':', '').trim();
    if (cleaned.isEmpty) return TimeOfDay.now();
    final h =
        int.tryParse(cleaned.substring(0, cleaned.length.clamp(0, 2))) ?? 0;
    final m = cleaned.length > 2
        ? (int.tryParse(cleaned.substring(2, cleaned.length.clamp(2, 4))) ?? 0)
        : 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static String formatHHmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// The zone called [name]: UTC when null, as flights without one are, or
  /// when this database doesn't have it (synced from a newer app).
  static tz.Location location(String? name) =>
      tz.timeZoneDatabase.locations[name] ?? tz.UTC;

  /// The name of the device's time zone. Dart only knows its offsets and
  /// abbreviations: this is the zone that matches them, UTC if none does.
  ///
  /// shortcut: compares two years around now, zones that differed only
  /// before that are taken for one another; use flutter_timezone if sessions
  /// that old need their zone.
  static String deviceZone() {
    final now = DateTime.now();
    final days = [
      for (var month = -12; month < 12; month++)
        DateTime(now.year, now.month + month),
    ];
    final matches = tz.timeZoneDatabase.locations.values.where(
      (l) => days.every(
        (d) => TZDateTime.from(d, l).timeZoneOffset == d.timeZoneOffset,
      ),
    );
    if (matches.isEmpty) return 'UTC';
    // Same offsets, other names: Lisbon and London.
    return matches
        .firstWhere(
          (l) => days.every(
            (d) =>
                TZDateTime.from(d, l).timeZone.abbreviation == d.timeZoneName,
          ),
          orElse: () => matches.first,
        )
        .name;
  }

  /// [text] (HH:mm) on [date], in the [ianaLocation] time zone.
  static TZDateTime parseDateTimeFromText(
    String text,
    DateTime date,
    String? ianaLocation,
  ) {
    final time = parseTimeOfDay(text);
    return TZDateTime(
      location(ianaLocation),
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Whether the clocks skip [text] (HH:mm) on the day of [parsed], which was
  /// read from it.
  static bool isSkipped(String text, TZDateTime parsed) =>
      TimeOfDay.fromDateTime(parsed) != parseTimeOfDay(text);

  /// The time zone at a position; null without one, or where none is known.
  static tz.Location? locationAt(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    try {
      return tz.getLocation(latLngToTimezoneString(latitude, longitude));
    } catch (_) {
      return null;
    }
  }
}
