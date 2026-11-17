import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/duration_formatter.dart';
import 'package:zenith/utils/time_input_formatter.dart';

void main() {
  final formatter = TotalTimeInputFormatter();

  String type(String oldText, String newText) => formatter
      .formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(text: newText),
      )
      .text;

  test('fills in from the right, the last two digits being minutes', () {
    expect(type('', '5'), '0:05');
    expect(type('0:05', '0:050'), '0:50');
    expect(type('0:50', '0:500'), '5:00');
    expect(type('5:00', '5:0030'), '500:30');
    expect(type('500:30', '500:301'), '5003:01');
  });

  test('deleting shifts the digits back', () {
    expect(type('5003:01', '5003:0'), '500:30');
    expect(type('0:05', '0:0'), '');
  });

  test('refuses more hours than allowed', () {
    expect(type('99999:59', '99999:591'), '99999:59');
  });

  test('what it types parses with as many hour digits', () {
    expect(
      DurationFormatter.parseHm(type('', '125030'), maxHourDigits: 5),
      const Duration(hours: 1250, minutes: 30),
    );
    // Not with the default two.
    expect(DurationFormatter.parseHm('1250:30'), isNull);
  });
}
