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

  /// [text] (HH:mm) on [date], in the [ianaLocation] time zone (the
  /// device's when null).
  static TZDateTime parseDateTimeFromText(
    String text,
    DateTime date,
    String? ianaLocation,
  ) {
    final time = parseTimeOfDay(text);
    return TZDateTime(
      ianaLocation != null ? tz.getLocation(ianaLocation) : tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// The time zone at a position; null without one, or where none is known.
  static tz.Location? locationAt(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    try {
      return tz.getLocation(latLngToTimezoneString(latitude, longitude));
    } catch (_) {
      return null;
    }
  }

  /// [utcTime] as HH:mm in the [ianaLocation] time zone.
  static String formatHHmmInTimezone(DateTime utcTime, String? ianaLocation) {
    final location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;
    return formatHHmm(
      TimeOfDay.fromDateTime(TZDateTime.from(utcTime, location)),
    );
  }
}
