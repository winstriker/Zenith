import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/time_input_formatter.dart';

void main() {
  final formatter = TimeInputFormatter();

  TextEditingValue format(String oldText, String newText) =>
      formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(text: newText),
      );

  test('leaves up to two digits untouched', () {
    expect(format('', '1').text, '1');
    expect(format('1', '12').text, '12');
  });

  test('inserts a colon after the hours', () {
    expect(format('12', '123').text, '12:3');
    expect(format('12:3', '12:34').text, '12:34');
  });

  test('rejects more than four digits', () {
    expect(format('12:34', '12:345').text, '12:34');
  });

  test('puts the cursor at the end', () {
    final value = format('12', '123');
    expect(value.selection, const TextSelection.collapsed(offset: 4));
  });
}
