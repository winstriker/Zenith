import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/pdf_export_service.dart';

final _dep = DateTime.utc(2026, 11, 13, 8);

FlightWithStats _flight(int id) => FlightWithStats(
  flight: Flight(
    id: id,
    title: 'A → B',
    departureTime: _dep.add(Duration(days: id)),
    arrivalTime: _dep.add(Duration(days: id, minutes: 90)),
    isRecording: false,
    proficiencyCheck: false,
    pilotRole: 'pic',
    dayLandings: 1,
  ),
  dataPoints: const [],
);

/// The cells of the totals row labelled [label] on each page.
List<List<String>> _totalsRows(String html, String label) => [
  for (final row in RegExp(
    '<tr class="row-data"><td colspan="7" class="text-right">$label</td>'
    '(.*?)</tr>',
  ).allMatches(html))
    [
      for (final cell in RegExp('<td[^>]*>(.*?)</td>').allMatches(row[1]!))
        cell[1]!,
    ],
];

void main() {
  final previous = const PreviousTotals()
      .withTime(LogbookTimeField.total, const Duration(hours: 1200, minutes: 5))
      .withTime(LogbookTimeField.singlePilotSe, const Duration(hours: 1200))
      .withLandings(day: 700);

  test('previous totals are carried into the first page', () {
    // 25 flights: two pages.
    final html = PdfExportService.buildLogbookHtml([
      for (var i = 1; i <= 25; i++) _flight(i),
    ], previousTotals: previous);
    final fromPrevious = _totalsRows(html, 'TOTAL FROM PREVIOUS PAGES');
    expect(fromPrevious, hasLength(2));
    // SE, ME, multi-pilot, total, PIC name, day landings.
    expect(fromPrevious[0].sublist(0, 6), [
      '1200:00',
      '',
      '',
      '1200:05',
      '',
      '700',
    ]);
    // Page 2 starts from page 1's grand total: + 20 flights of 1:30.
    expect(fromPrevious[1][3], '1230:05');
    expect(fromPrevious[1][5], '720');
    final grand = _totalsRows(html, 'TOTAL TIME');
    expect(grand[1][3], '1237:35');
  });

  test('without previous totals the first page starts empty', () {
    final html = PdfExportService.buildLogbookHtml([_flight(1)]);
    final fromPrevious = _totalsRows(html, 'TOTAL FROM PREVIOUS PAGES');
    expect(fromPrevious.single.sublist(0, 6), everyElement(''));
  });

  test("the pilot's signature signs every page", () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    final html = PdfExportService.buildLogbookHtml([
      for (var i = 1; i <= 25; i++) _flight(i),
    ], pilotSignature: png);
    expect(
      RegExp(
        '<img class="pilot-signature" src="data:image/png;base64,',
      ).allMatches(html),
      hasLength(2),
    );
    expect(
      PdfExportService.buildLogbookHtml([_flight(1)]),
      isNot(contains('<img class="pilot-signature"')),
    );
  });
}
