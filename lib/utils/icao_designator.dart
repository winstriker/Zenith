import 'package:flutter/services.dart';

/// ICAO aircraft type designators (Doc 8643) used by this app are always
/// exactly 4 characters: uppercase letters and digits (e.g. `C172`, `B738`).
final _designatorPattern = RegExp(r'^[A-Z0-9]{4}$');

const icaoDesignatorLength = 4;

/// Returns an error message, or null if [value] is a valid designator.
String? validateIcaoDesignator(String? value) {
  final v = value?.trim().toUpperCase() ?? '';
  if (v.isEmpty) return 'Required';
  if (v.length != icaoDesignatorLength) {
    return 'Must be exactly $icaoDesignatorLength characters';
  }
  if (!_designatorPattern.hasMatch(v)) {
    return 'Only letters and digits are allowed';
  }
  return null;
}

/// Restricts input to letters/digits and upper-cases it as the user types.
final List<TextInputFormatter> icaoDesignatorInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
  LengthLimitingTextInputFormatter(icaoDesignatorLength),
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.toUpperCase()),
  ),
];
