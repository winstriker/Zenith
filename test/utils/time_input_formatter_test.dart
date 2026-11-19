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

  test('puts the cursor at the end when typing at the end', () {
    final value = format('12', '123');
    expect(value.selection, const TextSelection.collapsed(offset: 4));
  });

  TextEditingValue edit(String oldText, String newText, int cursor) =>
      formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor),
        ),
      );

  test('edits in the middle keep the cursor there', () {
    // Delete the 2 of 12:34, then type 5 in its place.
    var value = edit('12:34', '1:34', 1);
    expect(value.text, '13:4');
    expect(value.selection.extentOffset, 1);
    value = edit('13:4', '153:4', 2);
    expect(value.text, '15:34');
    expect(value.selection.extentOffset, 3);
  });

  test('backspace over the colon deletes the digit before it', () {
    final value = edit('12:34', '1234', 2);
    expect(value.text, '13:4');
    expect(value.selection.extentOffset, 1);
  });
}
