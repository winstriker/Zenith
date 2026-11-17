import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';

void main() {
  test('round trips through JSON', () {
    final totals = const PreviousTotals()
        .withTime(
          LogbookTimeField.total,
          const Duration(hours: 1250, minutes: 30),
        )
        .withTime(LogbookTimeField.pic, const Duration(hours: 800))
        .withLandings(day: 900, night: 42);
    final back = PreviousTotals.fromJson(
      (jsonDecode(jsonEncode(totals.toJson())) as Map).cast(),
    );
    expect(back, totals);
    expect(back.time(LogbookTimeField.total).inMinutes, 1250 * 60 + 30);
    expect(back.time(LogbookTimeField.dual), Duration.zero);
  });

  test('zero clears a column', () {
    final totals = const PreviousTotals()
        .withTime(LogbookTimeField.night, const Duration(hours: 3))
        .withTime(LogbookTimeField.night, Duration.zero);
    expect(totals.isEmpty, isTrue);
    expect(totals.toJson(), isEmpty);
  });

  test('unknown or bad values are dropped', () {
    final totals = PreviousTotals.fromJson({
      'times': {'total': 60, 'warp': 5, 'pic': 'x', 'ifr': -3},
      'dayLandings': 'many',
      'nightLandings': 2,
    });
    expect(totals.times, {LogbookTimeField.total: const Duration(hours: 1)});
    expect(totals.dayLandings, 0);
    expect(totals.nightLandings, 2);
  });

  test('a damaged column reads as empty', () {
    expect(PreviousTotals.converter.fromSql('not json'), PreviousTotals.empty);
  });
}
