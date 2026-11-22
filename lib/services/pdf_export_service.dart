import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, visibleForTesting;
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../models/logbook_entry.dart';
import '../providers/user_provider.dart';
import 'database.dart';
import 'file_opener.dart';
import 'logbook_text_fit.dart';

const _rowsPerPage = 20;

final _log = Logger('PDF Export');

class _Totals {
  Duration se = Duration.zero;
  Duration me = Duration.zero;
  Duration multiPilot = Duration.zero;
  Duration total = Duration.zero;
  int dayLandings = 0;
  int nightLandings = 0;
  Duration night = Duration.zero;
  Duration ifr = Duration.zero;
  Duration pic = Duration.zero;
  Duration picus = Duration.zero;
  Duration coPilot = Duration.zero;
  Duration dual = Duration.zero;
  Duration instructor = Duration.zero;
  Duration fstd = Duration.zero;

  /// What was logged before the app, carried forward into the first page.
  /// Without a PICUS column, PICUS time is PIC time (AMC1 FCL.050(h)).
  static _Totals previous(PreviousTotals p, {required bool picusColumn}) =>
      _Totals()
        ..se = p.time(LogbookTimeField.singlePilotSe)
        ..me = p.time(LogbookTimeField.singlePilotMe)
        ..multiPilot = p.time(LogbookTimeField.multiPilot)
        ..total = p.time(LogbookTimeField.total)
        ..dayLandings = p.dayLandings
        ..nightLandings = p.nightLandings
        ..night = p.time(LogbookTimeField.night)
        ..ifr = p.time(LogbookTimeField.ifr)
        ..pic =
            p.time(LogbookTimeField.pic) +
            (picusColumn ? Duration.zero : p.time(LogbookTimeField.picus))
        ..picus = picusColumn ? p.time(LogbookTimeField.picus) : Duration.zero
        ..coPilot = p.time(LogbookTimeField.coPilot)
        ..dual = p.time(LogbookTimeField.dual)
        ..instructor = p.time(LogbookTimeField.instructor)
        ..fstd = p.time(LogbookTimeField.fstd);

  _Totals operator +(_Totals other) {
    return _Totals()
      ..se = se + other.se
      ..me = me + other.me
      ..multiPilot = multiPilot + other.multiPilot
      ..total = total + other.total
      ..dayLandings = dayLandings + other.dayLandings
      ..nightLandings = nightLandings + other.nightLandings
      ..night = night + other.night
      ..ifr = ifr + other.ifr
      ..pic = pic + other.pic
      ..picus = picus + other.picus
      ..coPilot = coPilot + other.coPilot
      ..dual = dual + other.dual
      ..instructor = instructor + other.instructor
      ..fstd = fstd + other.fstd;
  }
}

/// A flight's line of the logbook: its cells, and the height it takes.
/// [picus]: its PIC time is in the PICUS column. [notes]: descriptions of
/// its airports for under the table, by airport id.
typedef _Line = ({
  LogbookEntry entry,
  bool picus,
  Map<int, String> notes,
  String cells,
  double heightMm,
});

/// Content of column 12 (remarks) in the three totals rows.
enum _RemarksCell { certification, signature, coveredBySignature }

class PdfExportService {
  /// Width to height of a flight's remarks cell: a signature is fitted into
  /// it, and a photo of the paper logbook's remarks is cropped to it.
  static const remarksCellRatio = (x: 20, y: 3);

  /// Width to height of the space left for the pilot's signature in the
  /// "pilot's signature" box at the bottom of each page, under its label.
  static const pilotSignatureRatio = (x: 5, y: 1);

  /// [signatures] are the images (PNG or JPEG) laid over the remarks, by
  /// flight id. [pilotSignature] signs every page. [previousTotals] are
  /// carried forward into the first page. [pilotName], [address] and
  /// [licences] (one line per licence: kind and number) are the holder's
  /// personal details on the cover (AMC1 FCL.050(a)(1)).
  static Future<File> generateLogbook(
    List<FlightWithStats> flights, {
    Map<int, List<CrewMember>> crewByFlight = const {},
    Map<int, Uint8List> signatures = const {},
    Uint8List? pilotSignature,
    PreviousTotals previousTotals = PreviousTotals.empty,
    String? pilotName,
    PicNameMode picNameMode = PicNameMode.self,
    String? address,
    List<String> licences = const [],
    bool picusColumn = false,
  }) async {
    final html = buildLogbookHtml(
      flights,
      picusColumn: picusColumn,
      crewByFlight: crewByFlight,
      signatures: signatures,
      pilotSignature: pilotSignature,
      previousTotals: previousTotals,
      pilotName: pilotName,
      picNameMode: picNameMode,
      address: address,
      licences: licences,
    );
    final converter = HtmlToPdfConverter();
    final directory = await FileOpener.exportsDirectory();
    final file = await converter.convertHtmlToPdf(
      html: html,
      targetDirectory: directory.path,
      targetName:
          'logbook_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      pageSize: PdfPageSize.a4.landscape,
    );
    // Only after a successful export, so a failure keeps the previous one.
    await _deleteOlderExports(directory, keep: file);
    return file;
  }

  static Future<void> _deleteOlderExports(
    Directory directory, {
    required File keep,
  }) async {
    await for (final entity in directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File &&
          entity.path != keep.path &&
          name.startsWith('logbook_') &&
          name.endsWith('.pdf')) {
        try {
          await entity.delete();
        } catch (e, st) {
          _log.warning('Could not delete old export ${entity.path}', e, st);
        }
      }
    }
  }

  static String _fmtDur(Duration d) {
    if (d == Duration.zero) return '';
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Widths of the 23 columns, in % of the table.
  static const _columnWidths = <double>[
    5, 4, 3.5, 4, 3.5, 6.5, 4.5, 4, 4, 5, 4, 6, //
    3, 3, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 5, 2.5, 11,
  ];

  /// With a PICUS column after the PIC one, taken from PIC NAME, FSTD type
  /// and remarks.
  static const _picusColumnWidths = <double>[
    5, 4, 3.5, 4, 3.5, 6.5, 4.5, 4, 4, 5, 4, 5.5, //
    3, 3, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 4.5, 2.5, 8.5,
  ];

  /// Airports described under a page's table, at most: the room left there.
  // shortcut: counts notes, not their lines; a long custom note may wrap
  // and push the page; measure with LogbookTextFit if that shows up.
  static const _maxNotesPerPage = 10;

  /// Width of the table: an A4 landscape page less its margins.
  static const _tableWidthMm = (297 - 2 * 7) * 0.999;

  /// Height of a row whose text fits on its line.
  static const _rowHeightMm = 5.5;

  /// What a cell's padding and borders take from its height.
  static const _cellPaddingMm = 0.7;

  /// The height the data rows of a page may take: 20 rows of the usual
  /// height, plus part of the room left under the table for rows that grew
  /// to hold their text.
  static const _pageRowsBudgetMm = _rowsPerPage * _rowHeightMm + 16;

  /// Room for text in a column [widthPct] wide, with [sideMm] of padding.
  static double _textWidthMm(double widthPct, {double sideMm = 0.8}) =>
      widthPct * _tableWidthMm / 100 - sideMm;

  static String _points(double pt) =>
      pt == pt.roundToDouble() ? '${pt.toInt()}' : pt.toStringAsFixed(2);

  /// [text] in an element of [tag], at its fitted size, wrapping when it
  /// has to.
  static String _fittedTag(
    String tag,
    FittedText fit, {
    String classes = '',
    String extra = '',
  }) {
    final cls = [
      if (classes.isNotEmpty) classes,
      if (fit.wraps) 'wrap',
    ].join(' ');
    return '<$tag${cls.isEmpty ? '' : ' class="$cls"'} '
        'style="font-size:${_points(fit.points)}pt">'
        '${_escape(fit.text)}$extra</$tag>';
  }

  /// A cell [widthPct] wide whose text is fitted to it (see [LogbookTextFit]):
  /// set smaller, then on more lines, never cut off. Its text height is
  /// what the row needs for it.
  static ({String html, double heightMm}) _fittedCell(
    String text,
    double widthPct, {
    double maxPoints = 7,
    double minPoints = LogbookTextFit.minPrintablePoints,
    int maxLines = 1,
    String classes = '',
    String extra = '',
    double sideMm = 0.8,
  }) {
    if (text.trim().isEmpty) {
      return (
        html: '<td${classes.isEmpty ? '' : ' class="$classes"'}>$extra</td>',
        heightMm: 0,
      );
    }
    final fit = LogbookTextFit.fit(
      text.trim(),
      widthMm: _textWidthMm(widthPct, sideMm: sideMm),
      maxPoints: maxPoints,
      minPoints: minPoints,
      maxLines: maxLines,
    );
    return (
      html: _fittedTag('td', fit, classes: classes, extra: extra),
      heightMm: fit.heightMm,
    );
  }

  /// Column 4, aircraft "make, model, variant" (AMC1 FCL.050(a)(2)(iv)):
  /// the ICAO type designator, or the pilot's own type and subtitle line
  /// for the aircraft.
  static ({String html, double heightMm}) _aircraftTypeCell(
    AircraftWithStats? aircraft,
    double widthPct,
  ) {
    if (aircraft == null) return (html: '<td></td>', heightMm: 0);
    final width = _textWidthMm(widthPct);
    final type = LogbookTextFit.fit(aircraft.logbookTypeLine, widthMm: width);
    final subtitleText = aircraft.logbookSubtitleLine;
    final subtitle = subtitleText == null
        ? null
        : LogbookTextFit.fit(
            subtitleText,
            widthMm: width,
            maxPoints: LogbookTextFit.minPrintablePoints,
          );
    return (
      html:
          '<td class="type">${_fittedTag('div', type)}'
          '${subtitle == null ? '' : _fittedTag('div', subtitle, classes: 'subtitle')}'
          '</td>',
      heightMm: type.heightMm + (subtitle?.heightMm ?? 0),
    );
  }

  /// The first page: the holder's personal details (AMC1 FCL.050(a)(1)).
  static String _coverPage({
    required String? name,
    required String? address,
    required List<String> licences,
  }) {
    String field(String label, String? value) {
      final text = value?.trim() ?? '';
      return '<div class="cover-field"><div class="cover-label">$label</div>'
          '<div class="cover-value">'
          '${text.isEmpty ? '&nbsp;' : _escape(text).replaceAll('\n', '<br>')}'
          '</div></div>';
    }

    return '<div class="logbook-page cover">'
        '<h1>PILOT LOGBOOK</h1>'
        '${field("Holder's name(s)", name)}'
        '${field("Holder's licence number", licences.join('\n'))}'
        '${field("Holder's address", address)}'
        '<p class="cover-note">Electronic record kept in accordance with '
        'FCL.050 and AMC1 FCL.050 of Regulation (EU) No 1178/2011. All '
        'dates and times are UTC. Flight time is recorded from the moment '
        'the aircraft first moves to take off until it finally comes to rest '
        '(for helicopters, from rotor start until the rotor blades stop).</p>'
        '</div>';
  }

  static String _fmtInt(int n) => n > 0 ? '$n' : '';

  /// [image] (PNG or JPEG) as a data URI.
  static String _dataUri(Uint8List image) {
    final isPng =
        image.length > 4 &&
        image[0] == 0x89 &&
        image[1] == 0x50 &&
        image[2] == 0x4E &&
        image[3] == 0x47;
    return 'data:image/${isPng ? 'png' : 'jpeg'};base64,${base64Encode(image)}';
  }

  /// The remarks cell, with [signature] laid over the text when there is
  /// one. Up to 2 lines before the row grows.
  static ({String html, double heightMm}) _remarksCell(
    String remarks,
    Uint8List? signature,
    double widthPct,
  ) => _fittedCell(
    remarks,
    widthPct,
    maxLines: 2,
    sideMm: 1.4,
    classes: signature == null ? 'text-left' : 'text-left signed',
    extra: signature == null
        ? ''
        : '<img class="signature" src="${_dataUri(signature)}">',
  );

  /// The cells of [flight]'s logbook line, and the height it needs.
  /// [widths] has a PICUS column when [picusColumn].
  static _Line _line(
    FlightWithStats f,
    LogbookEntry entry,
    Uint8List? signature,
    String Function(DateTime) date,
    String Function(DateTime) time, {
    required bool picusColumn,
    required List<double> widths,
  }) {
    String duration(LogbookTimeField field) => _fmtDur(entry.time(field));
    final picus = picusColumn && f.flight.pilotRole == CrewRole.picus.name;
    // Past the PICUS column, when there is one, columns move one along.
    final shift = picusColumn ? 1 : 0;
    final notes = <int, String>{
      for (final a in [?f.departure, ?f.arrival]) a.id: ?a.logbookNoteLine,
    };
    // A simulator session only has its date, column 11 and remarks
    // (AMC1 FCL.050(i)(9)).
    final session = f.isSimulatorSession;
    String flown(String Function() value) => session ? '' : value();
    final fitted = [
      _fittedCell(f.departure?.logbookPlace ?? '', widths[1]),
      _fittedCell(f.arrival?.logbookPlace ?? '', widths[3]),
      _aircraftTypeCell(f.aircraftWithStats, widths[5]),
      _fittedCell(f.aircraftWithStats?.tailNumber ?? '', widths[6]),
      _fittedCell(entry.picName, widths[11]),
      _fittedCell(f.simulator?.logbookType ?? '', widths[20 + shift]),
      _remarksCell(entry.remarks, signature, widths[22 + shift]),
    ];
    final [dep, arr, type, registration, picName, fstdType, remarks] = fitted;
    final cells = StringBuffer()
      ..write('<td>${date(f.flight.departureTime)}</td>')
      ..write(dep.html)
      ..write('<td>${flown(() => time(f.flight.departureTime))}</td>')
      ..write(arr.html)
      ..write(
        '<td>${flown(() => f.flight.arrivalTime != null ? time(f.flight.arrivalTime!) : '')}</td>',
      )
      ..write(type.html)
      ..write(registration.html)
      ..write('<td>${duration(LogbookTimeField.singlePilotSe)}</td>')
      ..write('<td>${duration(LogbookTimeField.singlePilotMe)}</td>')
      ..write('<td>${duration(LogbookTimeField.multiPilot)}</td>')
      ..write('<td>${duration(LogbookTimeField.total)}</td>')
      ..write(picName.html)
      ..write('<td>${_fmtInt(entry.dayLandings)}</td>')
      ..write('<td>${_fmtInt(entry.nightLandings)}</td>')
      ..write('<td>${duration(LogbookTimeField.night)}</td>')
      ..write('<td>${duration(LogbookTimeField.ifr)}</td>')
      ..write('<td>${picus ? '' : duration(LogbookTimeField.pic)}</td>')
      ..write(
        picusColumn
            ? '<td>${picus ? duration(LogbookTimeField.pic) : ''}</td>'
            : '',
      )
      ..write('<td>${duration(LogbookTimeField.coPilot)}</td>')
      ..write('<td>${duration(LogbookTimeField.dual)}</td>')
      ..write('<td>${duration(LogbookTimeField.instructor)}</td>')
      ..write(fstdType.html)
      ..write('<td>${duration(LogbookTimeField.fstd)}</td>')
      ..write(remarks.html);
    final text = fitted.fold(0.0, (h, c) => max(h, c.heightMm));
    return (
      entry: entry,
      picus: picus,
      notes: notes,
      cells: cells.toString(),
      heightMm: max(_rowHeightMm, text + _cellPaddingMm),
    );
  }

  static _Totals _calcPageTotals(List<_Line> page) {
    final t = _Totals();
    for (final (:entry, :picus, notes: _, cells: _, heightMm: _) in page) {
      final e = entry;
      t.se += e.time(LogbookTimeField.singlePilotSe);
      t.me += e.time(LogbookTimeField.singlePilotMe);
      t.multiPilot += e.time(LogbookTimeField.multiPilot);
      t.total += e.time(LogbookTimeField.total);
      t.dayLandings += e.dayLandings;
      t.nightLandings += e.nightLandings;
      t.night += e.time(LogbookTimeField.night);
      t.ifr += e.time(LogbookTimeField.ifr);
      if (picus) {
        t.picus += e.time(LogbookTimeField.pic);
      } else {
        t.pic += e.time(LogbookTimeField.pic);
      }
      t.coPilot += e.time(LogbookTimeField.coPilot);
      t.dual += e.time(LogbookTimeField.dual);
      t.instructor += e.time(LogbookTimeField.instructor);
      t.fstd += e.time(LogbookTimeField.fstd);
    }
    return t;
  }

  /// [pilotSignature] is a data URI, put in the signature box.
  static String _totalsRow(
    String label,
    _Totals t,
    _RemarksCell remarks, {
    required bool picusColumn,
    String? pilotSignature,
  }) {
    final buf = StringBuffer();
    buf.write('<tr class="row-data">');
    buf.write('<td colspan="7" class="text-right">$label</td>');
    buf.write('<td>${_fmtDur(t.se)}</td>');
    buf.write('<td>${_fmtDur(t.me)}</td>');
    buf.write('<td>${_fmtDur(t.multiPilot)}</td>');
    buf.write('<td>${_fmtDur(t.total)}</td>');
    buf.write('<td></td>'); // PIC name
    buf.write('<td>${_fmtInt(t.dayLandings)}</td>');
    buf.write('<td>${_fmtInt(t.nightLandings)}</td>');
    buf.write('<td>${_fmtDur(t.night)}</td>');
    buf.write('<td>${_fmtDur(t.ifr)}</td>');
    buf.write('<td>${_fmtDur(t.pic)}</td>');
    if (picusColumn) buf.write('<td>${_fmtDur(t.picus)}</td>');
    buf.write('<td>${_fmtDur(t.coPilot)}</td>');
    buf.write('<td>${_fmtDur(t.dual)}</td>');
    buf.write('<td>${_fmtDur(t.instructor)}</td>');
    buf.write('<td></td>'); // FSTD type
    buf.write('<td>${_fmtDur(t.fstd)}</td>');
    switch (remarks) {
      case _RemarksCell.certification:
        buf.write(
          '<td class="text-top text-left bold wrap" style="font-size: 6pt;">I certify that the entries in this log are true.</td>',
        );
      case _RemarksCell.signature:
        buf.write(
          '<td rowspan="2" class="text-top text-left bold signed" style="font-size: 6.5pt;">PILOT\'S SIGNATURE',
        );
        if (pilotSignature != null) {
          buf.write('<img class="pilot-signature" src="$pilotSignature">');
        }
        buf.write('</td>');
      case _RemarksCell.coveredBySignature:
        // Column 12 is occupied by the signature cell's rowspan above.
        break;
    }
    buf.write('</tr>');
    return buf.toString();
  }

  static String _tableHeader({required bool picusColumn}) {
    final functions = picusColumn ? 5 : 4;
    return '''
<thead>
  <tr>
    <th class="bold">1</th>
    <th colspan="2" class="bold">2</th>
    <th colspan="2" class="bold">3</th>
    <th colspan="2" class="bold">4</th>
    <th colspan="3" class="bold">5</th>
    <th class="bold">6</th>
    <th class="bold">7</th>
    <th colspan="2" class="bold">8</th>
    <th colspan="2" class="bold">9</th>
    <th colspan="$functions" class="bold">10</th>
    <th colspan="2" class="bold">11</th>
    <th class="bold">12</th>
  </tr>
  <tr>
    <th rowspan="2">DATE<br>(dd/mm/yy)</th>
    <th colspan="2">DEPARTURE (UTC)</th>
    <th colspan="2">ARRIVAL (UTC)</th>
    <th colspan="2">AIRCRAFT</th>
    <th colspan="2">SINGLE-PILOT TIME</th>
    <th rowspan="2">MULTI-PILOT<br>TIME</th>
    <th rowspan="2">TOTAL<br>TIME</th>
    <th rowspan="2">PIC NAME</th>
    <th colspan="2">LANDINGS</th>
    <th colspan="2">OP. COND. TIME</th>
    <th colspan="$functions">PILOT FUNCTION TIME</th>
    <th colspan="2">FSTD SESSION</th>
    <th rowspan="2">REMARKS AND<br>ENDORSEMENTS</th>
  </tr>
  <tr>
    <th>PLACE</th><th>TIME</th>
    <th>PLACE</th><th>TIME</th>
    <th>MAKE, MODEL,<br>VARIANT</th><th>REGIS-<br>TRATION</th>
    <th>SE</th><th>ME</th>
    <th>DAY</th><th>NIGHT</th>
    <th>NIGHT</th><th>IFR</th>
    <th>PIC</th>${picusColumn ? '<th>PICUS</th>' : ''}<th>COP</th><th>DUAL</th><th>INSTR</th>
    <th>TYPE</th><th>TIME</th>
  </tr>
</thead>''';
  }

  /// The logbook as HTML, for [generateLogbook] to print.
  @visibleForTesting
  static String buildLogbookHtml(
    List<FlightWithStats> flights, {
    Map<int, List<CrewMember>> crewByFlight = const {},
    Map<int, Uint8List> signatures = const {},
    Uint8List? pilotSignature,
    PreviousTotals previousTotals = PreviousTotals.empty,
    String? pilotName,
    PicNameMode picNameMode = PicNameMode.self,
    String? address,
    List<String> licences = const [],
    bool picusColumn = false,
  }) {
    final widths = picusColumn ? _picusColumnWidths : _columnWidths;
    // Encoded once: the same picture signs every page.
    final pilotSignatureUri = pilotSignature == null
        ? null
        : _dataUri(pilotSignature);
    // AMC1 FCL.050(i)(1), (2): the date the flight commences and all times
    // in UTC.
    final dateFmt = DateFormat('dd/MM/yy');
    final timeFmt = DateFormat('HH:mm');
    String date(DateTime d) => dateFmt.format(d.toUtc());
    String time(DateTime d) => timeFmt.format(d.toUtc());
    final selfPicName = picNameMode == PicNameMode.self
        ? 'SELF'
        : (pilotName ?? '');

    // Oldest first, as a paper logbook is filled in.
    final chronological = [
      ...flights,
    ]..sort((a, b) => a.flight.departureTime.compareTo(b.flight.departureTime));
    final entries = [
      for (final f in chronological)
        (
          flight: f,
          entry: LogbookEntry.of(
            f,
            crew: crewByFlight[f.flight.id] ?? const [],
            selfPicName: selfPicName,
          ),
        ),
    ];
    final lines = [
      for (final (:flight, :entry) in entries)
        _line(
          flight,
          entry,
          signatures[flight.flight.id],
          date,
          time,
          picusColumn: picusColumn,
          widths: widths,
        ),
    ];
    // At most 20 lines a page, fewer when some grew taller to hold their
    // text, or their airports' notes would not fit under the table: the
    // page never runs over.
    final pages = <List<_Line>>[[]];
    var used = 0.0;
    var noted = <int>{};
    for (final line in lines) {
      final page = pages.last;
      if (page.isNotEmpty &&
          (page.length == _rowsPerPage ||
              used + line.heightMm > _pageRowsBudgetMm ||
              {...noted, ...line.notes.keys}.length > _maxNotesPerPage)) {
        pages.add([]);
        used = 0;
        noted = {};
      }
      pages.last.add(line);
      used += line.heightMm;
      noted.addAll(line.notes.keys);
    }

    // iOS's WebKit prints without the @page margins, so each page gets them
    // as padding, and drops collapsed table borders under 0.75px.
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final pageMargin = ios ? '7mm 7mm 0' : '0';
    final cellBorder = ios ? '0.75px' : '0.2px';
    final buf = StringBuffer();
    buf.write('''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  @page {
    size: A4 landscape;
    margin: 7mm;
    background-color: #ffffff;
  }
  html, body {
    margin: 0;
    padding: 0;
    background: #ffffff;
    /* No font boosting by the WebView: sizes print as set. */
    -webkit-text-size-adjust: none;
    text-size-adjust: none;
  }
  body {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 7.5pt;
    color: black;
  }
  .logbook-page {
    page-break-after: always;
    padding: $pageMargin;
  }
  .logbook-page:last-child {
    page-break-after: avoid;
  }
  table {
    width: 99.9%;
    border-collapse: collapse;
    table-layout: fixed;
    border: 1.5px solid black;
  }
  th, td {
    border: $cellBorder solid black;
    text-align: center;
    vertical-align: middle;
    padding: 1px 1px;
    box-sizing: border-box;
    word-wrap: break-word;
    overflow: hidden;
  }
  /* Vertical centring: the font's line box sits high for capitals and
     digits (no descenders), so a little more padding above than below
     brings the ink to the middle of the cell. */
  th {
    font-weight: bold;
    font-size: 5pt;
    padding: 9.5px 1px 6.5px 1px;
    line-height: 1.1;
  }
  .row-data td {
    height: 5.5mm;
    font-size: 7pt;
    line-height: 1.15;
    white-space: nowrap;
    padding-top: 2.25px;
    padding-bottom: 0;
  }
  /* Text too long for its cell at the smallest size: on more lines, the
     row growing to hold them. */
  .row-data .wrap {
    white-space: normal;
    overflow-wrap: anywhere;
    word-break: break-word;
  }
  .bold { font-weight: bold; }
  .text-right {
    text-align: right;
    padding-right: 4px;
    font-weight: bold;
  }
  .text-left {
    text-align: left;
    padding-left: 4px;
  }
  /* The certification and the pilot's signature box stay at the top. */
  .row-data td.text-top {
    vertical-align: top;
    padding-top: 3px;
  }
  .signed { position: relative; }
  .signature {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    object-position: center;
  }
  .pilot-signature {
    position: absolute;
    top: 3.2mm;
    left: 0;
    width: 100%;
    height: calc(100% - 3.4mm);
    object-fit: contain;
    object-position: center;
  }
  .bg-grey { background-color: #f2f2f2; }
  .airport-notes {
    margin-top: 1.5mm;
    font-size: 6pt;
    line-height: 1.25;
  }
  td.type { text-align: center; }
  .cover {
    padding: 30mm 25mm 0 25mm;
    font-size: 11pt;
  }
  .cover h1 {
    text-align: center;
    font-size: 26pt;
    letter-spacing: 2pt;
    margin: 0 0 18mm 0;
  }
  .cover-field { margin-bottom: 9mm; }
  .cover-label {
    font-size: 8pt;
    font-weight: bold;
    text-transform: uppercase;
  }
  .cover-value {
    border-bottom: 0.5px solid black;
    min-height: 7mm;
    padding: 2mm 0 1mm 0;
  }
  .cover-note {
    margin-top: 14mm;
    font-size: 8pt;
    color: #333333;
  }
</style>
</head>
<body>
''');

    buf.write(
      _coverPage(name: pilotName, address: address, licences: licences),
    );

    var prevTotals = _Totals.previous(previousTotals, picusColumn: picusColumn);

    for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final pageFlights = pages[pageIdx];
      final pageTotals = _calcPageTotals(pageFlights);
      final pageHeight = pageFlights.fold(0.0, (h, l) => h + l.heightMm);
      // Empty lines up to 20, as far as the page has room.
      final emptyLines = min(
        _rowsPerPage - pageFlights.length,
        ((_pageRowsBudgetMm - pageHeight) / _rowHeightMm).floor(),
      );
      final grandTotals = prevTotals + pageTotals;

      buf.write('<div class="logbook-page">');
      buf.write('<table>');
      buf.write('<colgroup>');
      for (final width in widths) {
        buf.write('<col style="width:$width%">');
      }
      buf.write('</colgroup>');
      buf.write(_tableHeader(picusColumn: picusColumn));
      buf.write('<tbody>');

      for (int i = 0; i < pageFlights.length + emptyLines; i++) {
        final grey = (i + 1) % 3 == 0 ? ' bg-grey' : '';
        buf.write('<tr class="row-data$grey">');
        if (i < pageFlights.length) {
          buf.write(pageFlights[i].cells);
        } else {
          for (int j = 0; j < widths.length; j++) {
            buf.write('<td></td>');
          }
        }
        buf.write('</tr>');
      }

      // Totals rows
      buf.write(
        _totalsRow(
          'TOTAL THIS PAGE',
          pageTotals,
          _RemarksCell.certification,
          picusColumn: picusColumn,
        ),
      );
      buf.write(
        _totalsRow(
          'TOTAL FROM PREVIOUS PAGES',
          prevTotals,
          _RemarksCell.signature,
          picusColumn: picusColumn,
          pilotSignature: pilotSignatureUri,
        ),
      );
      buf.write(
        _totalsRow(
          'TOTAL TIME',
          grandTotals,
          _RemarksCell.coveredBySignature,
          picusColumn: picusColumn,
        ),
      );

      buf.write('</tbody></table>');
      final notes = {for (final line in pageFlights) ...line.notes};
      if (notes.isNotEmpty) {
        buf.write('<div class="airport-notes">');
        for (final note in notes.values) {
          buf.write('<div>${_escape(note)}</div>');
        }
        buf.write('</div>');
      }
      buf.write('</div>');

      prevTotals = grandTotals;
    }

    buf.write('</body></html>');
    return buf.toString();
  }
}
