import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : text.length;
    // Backspace over the colon deletes the digit before it, as it looks.
    if (oldValue.text.length - text.length == 1 &&
        text.replaceAll(':', '') == oldValue.text.replaceAll(':', '') &&
        cursor > 0) {
      text = text.substring(0, cursor - 1) + text.substring(cursor);
      cursor--;
    }
    // Digits left of the cursor, so an edit in the middle keeps its place.
    final before = text.substring(0, cursor).replaceAll(':', '').length;
    final digits = text.replaceAll(':', '');
    if (digits.length > 4) {
      return oldValue;
    }
    String formatted;
    if (digits.length <= 2) {
      formatted = digits;
    } else {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: before >= 2 && formatted.length > 2 ? before + 1 : before,
      ),
    );
  }
}

/// Types a long duration (a logbook total) as H:MM from the right, like a
/// till: '5' is 0:05, '1230' is 12:30, '125030' is 1250:30. The text is
/// always a valid duration, with up to [maxHourDigits] digits of hours.
class TotalTimeInputFormatter extends TextInputFormatter {
  TotalTimeInputFormatter({this.maxHourDigits = 5});
  final int maxHourDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp('^0+'), '');
    if (digits.length > maxHourDigits + 2) return oldValue;
    final formatted = digits.isEmpty ? '' : format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// [digits] as H:MM, the last two being the minutes.
  static String format(String digits) {
    final padded = digits.padLeft(3, '0');
    final split = padded.length - 2;
    return '${padded.substring(0, split)}:${padded.substring(split)}';
  }
}
