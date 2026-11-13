import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/icao_designator.dart';

void main() {
  group('validateIcaoDesignator', () {
    test('accepts 4 letters/digits', () {
      expect(validateIcaoDesignator('C172'), isNull);
      expect(validateIcaoDesignator('B738'), isNull);
      expect(validateIcaoDesignator('glid'), isNull);
    });

    test('rejects empty, wrong length or symbols', () {
      expect(validateIcaoDesignator(null), 'Required');
      expect(validateIcaoDesignator('  '), 'Required');
      expect(validateIcaoDesignator('C17'), isNotNull);
      expect(validateIcaoDesignator('C1720'), isNotNull);
      expect(validateIcaoDesignator('C-17'), isNotNull);
    });
  });

  test('input formatters upper-case, strip symbols and cap at 4', () {
    var value = TextEditingValue.empty;
    for (final f in icaoDesignatorInputFormatters) {
      value = f.formatEditUpdate(
        TextEditingValue.empty,
        f == icaoDesignatorInputFormatters.first
            ? const TextEditingValue(text: 'c-1729')
            : value,
      );
    }
    expect(value.text, 'C172');
  });
}
