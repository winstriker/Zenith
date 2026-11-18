import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/logbook_text_fit.dart';

void main() {
  test('short text keeps the full size on one line', () {
    final fit = LogbookTextFit.fit('C172', widthMm: 17);
    expect(fit.points, 7);
    expect(fit.lines, 1);
    expect(fit.wraps, isFalse);
  });

  test('longer text is set smaller before it wraps', () {
    final fit = LogbookTextFit.fit('B747-400 BCF', widthMm: 17);
    expect(fit.points, lessThan(7));
    expect(fit.points, greaterThanOrEqualTo(6));
    expect(fit.lines, 1);
    expect(
      LogbookTextFit.widthMm('B747-400 BCF', fit.points),
      lessThanOrEqualTo(17),
    );
  });

  test('text too long at the smallest size wraps, never cut', () {
    const text =
        'Proficiency check, examiner Marco Rossi. Night rating training '
        'with circuits, crosswind landings and a diversion to an alternate';
    final fit = LogbookTextFit.fit(text, widthMm: 30, maxLines: 2);
    expect(fit.points, LogbookTextFit.minPrintablePoints);
    expect(fit.lines, greaterThan(2));
    // Taller than a row of the usual height: the row grows.
    expect(fit.heightMm, greaterThan(LogbookTextFit.rowTextHeightMm));
  });

  test('a word longer than a line is broken over lines', () {
    expect(
      LogbookTextFit.linesFor('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 7, 10),
      greaterThan(1),
    );
  });

  test('never smaller than the WebView prints', () {
    final fit = LogbookTextFit.fit(
      'Diamond HK-36 TTC ECO Super Dimona',
      widthMm: 17,
      minPoints: 3,
    );
    expect(fit.points, LogbookTextFit.minPrintablePoints);
    expect(fit.wraps, isTrue);
  });
}
