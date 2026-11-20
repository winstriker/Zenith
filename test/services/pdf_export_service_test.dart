import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
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

  test('dates and times are UTC (AMC1 FCL.050(i)(2))', () {
    final dep = DateTime.utc(2026, 11, 13, 23, 30);
    final html = PdfExportService.buildLogbookHtml([
      FlightWithStats(
        flight: Flight(
          id: 1,
          title: 'A → B',
          // Stored times come back in the device's time zone.
          departureTime: dep.toLocal(),
          arrivalTime: dep.add(const Duration(minutes: 45)).toLocal(),
          isRecording: false,
          proficiencyCheck: false,
          pilotRole: 'pic',
        ),
        dataPoints: const [],
      ),
    ]);
    expect(html, contains('<td>13/11/26</td>'));
    expect(html, contains('<td>23:30</td>'));
    expect(html, contains('<td>00:15</td>'));
    expect(html, contains('DEPARTURE (UTC)'));
  });

  test("the cover has the holder's personal details", () {
    final html = PdfExportService.buildLogbookHtml(
      [_flight(1)],
      pilotName: 'Mario Rossi',
      address: 'Via Roma 1\n20100 Milano',
      licences: const ['PPL(A) IT.FCL.1234'],
    );
    expect(html, contains('PILOT LOGBOOK'));
    expect(html, contains('Mario Rossi'));
    expect(html, contains('Via Roma 1<br>20100 Milano'));
    expect(html, contains('PPL(A) IT.FCL.1234'));
  });

  AircraftWithStats aircraft({String? type, String? subtitle}) =>
      AircraftWithStats(
        id: 1,
        tailNumber: 'I-ABCD',
        icaoAircraft: 1,
        aircraftClass: AircraftClass.sepLand,
        description: AircraftDescription.landplane,
        modelFullName: '172 Skyhawk',
        designator: 'C172',
        manufacturer: 'CESSNA',
        engineCount: 1,
        engineType: EngineType.piston,
        wakeTurbolenceCategory: WakeTurbulenceCategory.L,
        wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
        userInserted: false,
        flightCount: 1,
        logbookType: type,
        logbookSubtitle: subtitle,
      );

  FlightWithStats inAircraft(FlightWithStats f, AircraftWithStats a) =>
      FlightWithStats(
        flight: f.flight,
        dataPoints: const [],
        aircraftWithStats: a,
      );

  test('the aircraft is logged by its ICAO type by default', () {
    final html = PdfExportService.buildLogbookHtml([
      inAircraft(_flight(1), aircraft()),
    ]);
    expect(
      html,
      contains('<td class="type"><div style="font-size:7pt">C172</div></td>'),
    );
    expect(html, isNot(contains('Skyhawk')));
    expect(html, contains('<td style="font-size:7pt">I-ABCD</td>'));
  });

  test("the aircraft's logbook override replaces it, with a subtitle", () {
    final html = PdfExportService.buildLogbookHtml([
      inAircraft(
        _flight(1),
        aircraft(type: 'B747', subtitle: '747-400F Freighter, GE engines'),
      ),
    ]);
    expect(html, contains('<div style="font-size:7pt">B747</div>'));
    // At the smallest printable size, on as many lines as it takes.
    expect(
      html,
      contains(
        '<div class="subtitle wrap" style="font-size:6pt">'
        '747-400F Freighter, GE engines</div>',
      ),
    );
  });

  test('long remarks get smaller and wrap; the page keeps its height', () {
    final long = [
      for (var i = 1; i <= 20; i++)
        FlightWithStats(
          flight: _flight(i).flight.copyWith(
            remarks: const Value(
              'Night rating training with circuits, crosswind landings, a '
              'practice diversion to the alternate and an engine failure '
              'after take-off, all briefed and debriefed with the instructor',
            ),
          ),
          dataPoints: const [],
        ),
    ];
    final html = PdfExportService.buildLogbookHtml(long);
    expect(html, contains('class="text-left wrap"'));
    // Rows that grew to hold their remarks: 20 of them don't fit one page.
    expect(_totalsRows(html, 'TOTAL THIS PAGE').length, greaterThan(1));
    // Every flight is still there.
    expect(
      RegExp('Night rating training with circuits').allMatches(html),
      hasLength(20),
    );
  });

  test('the PICUS column takes PICUS time out of the PIC one', () {
    final picus = FlightWithStats(
      flight: _flight(2).flight.copyWith(pilotRole: const Value('picus')),
      dataPoints: const [],
    );
    // Landings, night, IFR, PIC, then PICUS (with the column) and COP.
    List<String> functions(String html) =>
        _totalsRows(html, 'TOTAL THIS PAGE').single.sublist(5, 12);

    final without = PdfExportService.buildLogbookHtml([_flight(1), picus]);
    expect(without, isNot(contains('<th>PICUS</th>')));
    expect(functions(without).sublist(4, 6), ['03:00', '']);

    final html = PdfExportService.buildLogbookHtml([
      _flight(1),
      picus,
    ], picusColumn: true);
    expect(html, contains('<th>PIC</th><th>PICUS</th><th>COP</th>'));
    expect(functions(html), ['2', '', '', '', '01:30', '01:30', '']);
  });

  Airport airport(int id, {String? icao}) => Airport(
    id: id,
    ident: icao ?? 'IT-0042',
    type: AirportType.smallAirport,
    name: 'Aviosuperficie Rossi',
    latitudeDeg: 45.5,
    longitudeDeg: -9.27666,
    elevationFt: 400,
    continent: 'EU',
    isoCountry: 'IT',
    isoRegion: 'IT-25',
    icaoCode: icao,
  );

  FlightWithStats between(Airport dep, Airport arr) => FlightWithStats(
    flight: _flight(1).flight,
    dataPoints: const [],
    departure: dep,
    arrival: arr,
  );

  test('a non-ICAO airport is described under the page', () {
    final html = PdfExportService.buildLogbookHtml([
      between(airport(1, icao: 'LIML'), airport(2)),
    ]);
    expect(
      html,
      contains(
        '<div class="airport-notes"><div>IT-0042 – Aviosuperficie Rossi, IT'
        " – 45°30.00'N 009°16.60'W – elev. 400 ft</div></div>",
      ),
    );
    expect(html, isNot(contains('LIML –')));
  });

  test("an airport's logbook override changes its ident and note", () {
    final html = PdfExportService.buildLogbookHtml([
      between(
        airport(1, icao: 'LIML').copyWith(logbookAnnotate: const Value(true)),
        airport(2).copyWith(
          logbookIdent: const Value('ROSSI'),
          logbookNote: const Value('Strip by the river'),
        ),
      ),
    ]);
    expect(html, contains('>ROSSI</td>'));
    expect(html, contains('<div>LIML – Aviosuperficie Rossi'));
    expect(html, contains('<div>Strip by the river</div>'));

    final off = PdfExportService.buildLogbookHtml([
      between(
        airport(1, icao: 'LIML'),
        airport(2).copyWith(logbookAnnotate: const Value(false)),
      ),
    ]);
    expect(off, isNot(contains('<div class="airport-notes">')));
  });

  test('an airport used by several flights of a page is noted once', () {
    final html = PdfExportService.buildLogbookHtml([
      between(airport(2), airport(2)),
      between(airport(1, icao: 'LIML'), airport(2)),
    ]);
    expect(RegExp('<div>IT-0042 – ').allMatches(html), hasLength(1));
  });

  test('a page holds the notes of at most 10 airports', () {
    final html = PdfExportService.buildLogbookHtml([
      for (var i = 1; i <= 6; i++) between(airport(i * 2), airport(i * 2 + 1)),
    ]);
    expect(_totalsRows(html, 'TOTAL THIS PAGE'), hasLength(2));
  });

  test('previous PICUS time has its column, or is PIC time without it', () {
    final totals = const PreviousTotals()
        .withTime(LogbookTimeField.pic, const Duration(hours: 100))
        .withTime(LogbookTimeField.picus, const Duration(hours: 20));
    // PIC, then PICUS (with the column) and COP.
    List<String> functions(String html) =>
        _totalsRows(html, 'TOTAL FROM PREVIOUS PAGES').single.sublist(9, 11);

    expect(
      functions(
        PdfExportService.buildLogbookHtml([_flight(1)], previousTotals: totals),
      ),
      ['120:00', ''],
    );
    expect(
      functions(
        PdfExportService.buildLogbookHtml(
          [_flight(1)],
          previousTotals: totals,
          picusColumn: true,
        ),
      ),
      ['100:00', '20:00'],
    );
  });
}
