import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/duration_formatter.dart';

void main() {
  const d = Duration(hours: 1, minutes: 2, seconds: 30);

  test('hms', () {
    expect(DurationFormatter.hms(d), '1:02:30');
    expect(DurationFormatter.hms(Duration.zero), '0:00:00');
  });

  test('hm', () {
    expect(DurationFormatter.hm(d), '01:02');
    expect(DurationFormatter.hm(const Duration(hours: 12)), '12:00');
  });

  test('descriptive', () {
    expect(
      DurationFormatter.descriptive(const Duration(hours: 2, minutes: 30)),
      '2h 30m',
    );
    expect(DurationFormatter.descriptive(const Duration(hours: 3)), '3h');
    expect(DurationFormatter.descriptive(const Duration(minutes: 45)), '45m');
    expect(DurationFormatter.descriptive(Duration.zero), '0m');
  });
}
