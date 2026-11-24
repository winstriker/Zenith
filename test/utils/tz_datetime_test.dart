import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:zenith/utils/tz_datetime.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('parseTimeOfDay', () {
    test('parses HH:mm and HHmm', () {
      expect(
        TZDateTimeParser.parseTimeOfDay('09:45'),
        const TimeOfDay(hour: 9, minute: 45),
      );
      expect(
        TZDateTimeParser.parseTimeOfDay('1730'),
        const TimeOfDay(hour: 17, minute: 30),
      );
    });

    test('clamps out-of-range values', () {
      expect(
        TZDateTimeParser.parseTimeOfDay('99:99'),
        const TimeOfDay(hour: 23, minute: 59),
      );
    });

    test('treats hours-only input as minute 0', () {
      expect(
        TZDateTimeParser.parseTimeOfDay('7'),
        const TimeOfDay(hour: 7, minute: 0),
      );
    });
  });

  test('formatHHmm pads values', () {
    expect(
      TZDateTimeParser.formatHHmm(const TimeOfDay(hour: 5, minute: 3)),
      '05:03',
    );
  });

  test('parseDateTimeFromText accounts for the time zone', () {
    // 10:00 in Rome (UTC+1 in January) is an hour before 10:00 in London.
    final date = DateTime(2026, 1, 15);
    final rome = TZDateTimeParser.parseDateTimeFromText(
      '10:00',
      date,
      'Europe/Rome',
    );
    final london = TZDateTimeParser.parseDateTimeFromText(
      '10:00',
      date,
      'Europe/London',
    );
    expect(london.difference(rome), const Duration(hours: 1));
  });

  test('formatHHmmInTimezone converts from UTC', () {
    // 12:00 UTC on 15 Jul 2026 is 14:00 in Rome (CEST, UTC+2).
    expect(
      TZDateTimeParser.formatHHmmInTimezone(
        DateTime.utc(2026, 7, 15, 12),
        'Europe/Rome',
      ),
      '14:00',
    );
  });
}
