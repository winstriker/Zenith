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

  group('formatBlockTime', () {
    test('formats hours and minutes', () {
      expect(
        TZDateTimeParser.formatBlockTime(const Duration(hours: 2, minutes: 5)),
        '2:05',
      );
    });

    test('returns 0:00 for null or negative durations', () {
      expect(TZDateTimeParser.formatBlockTime(null), '0:00');
      expect(
        TZDateTimeParser.formatBlockTime(const Duration(minutes: -10)),
        '0:00',
      );
    });
  });

  group('calculateBlockTime', () {
    test('accounts for different departure/arrival timezones', () {
      // 10:00 in Rome (UTC+1 in January) -> 10:00 in London (UTC+0)
      // is a 1h block time.
      final dep = TextEditingController(text: '10:00');
      final arr = TextEditingController(text: '10:00');
      addTearDown(dep.dispose);
      addTearDown(arr.dispose);
      final date = DateTime(2026, 1, 15);

      final block = TZDateTimeParser.calculateBlockTime(
        dep,
        date,
        'Europe/Rome',
        arr,
        date,
        'Europe/London',
      );

      expect(block, const Duration(hours: 1));
    });

    test('returns null when arrival is missing', () {
      final dep = TextEditingController(text: '10:00');
      final arr = TextEditingController();
      addTearDown(dep.dispose);
      addTearDown(arr.dispose);

      expect(
        TZDateTimeParser.calculateBlockTime(
          dep,
          DateTime(2026),
          null,
          arr,
          DateTime(2026),
          null,
        ),
        isNull,
      );
    });
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
