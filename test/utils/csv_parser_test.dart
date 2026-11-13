import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/csv_parser.dart';

void main() {
  group('parseCsv', () {
    test('parses simple rows', () {
      expect(parseCsv('a,b,c\n1,2,3\n'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('handles a last row without trailing newline', () {
      expect(parseCsv('a,b\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('handles quoted fields with commas, newlines and escaped quotes', () {
      expect(parseCsv('"x, y","line1\nline2","say ""hi"""\n'), [
        ['x, y', 'line1\nline2', 'say "hi"'],
      ]);
    });

    test('keeps empty fields and ignores CR and blank lines', () {
      expect(parseCsv('a,,c\r\n\r\n1,2,\r\n'), [
        ['a', '', 'c'],
        ['1', '2', ''],
      ]);
    });

    test('returns no rows for empty input', () {
      expect(parseCsv(''), isEmpty);
    });
  });
}
