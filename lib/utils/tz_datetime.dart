import 'package:flutter/material.dart';
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

  static String formatHHmm(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TZDateTime parseDateTimeFromText(
    String text,
    DateTime date,
    String? ianaLocation,
  ) {
    final time = parseTimeOfDay(text);

    final tz.Location location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;

    return TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static TZDateTime parseDateTime(
    TextEditingController controller,
    DateTime date,
    String? ianaLocation,
  ) {
    final time = parseTimeOfDay(controller.text);

    final tz.Location location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;

    return TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static TZDateTime parseDateTimeFromTimeOfDay(
    TimeOfDay time,
    DateTime date,
    String? ianaLocation,
  ) {
    final tz.Location location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;

    return TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static Duration? calculateBlockTime(
    TextEditingController depController,
    DateTime depDate,
    String? depIanaLocation,
    TextEditingController arrController,
    DateTime? arrDate,
    String? arrIanaLocation,
  ) {
    if (arrController.text.isEmpty || arrDate == null) return null;

    final depTZ = parseDateTime(depController, depDate, depIanaLocation);
    final arrTZ = parseDateTime(arrController, arrDate, arrIanaLocation);

    return arrTZ.difference(depTZ);
  }

  static String formatBlockTime(Duration? duration) {
    if (duration == null || duration.isNegative) return '0:00';
    final totalMinutes = duration.inMinutes;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  /// Formats a UTC DateTime as HH:mm in the given IANA timezone
  static String formatHHmmInTimezone(DateTime utcTime, String? ianaLocation) {
    final location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;
    final local = tz.TZDateTime.from(utcTime, location);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
