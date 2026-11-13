import 'dart:io';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../models/crew_rules.dart';
import '../providers/user_provider.dart';
import 'database.dart';
import 'file_opener.dart';

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
  Duration coPilot = Duration.zero;
  Duration dual = Duration.zero;
  Duration instructor = Duration.zero;

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
      ..coPilot = coPilot + other.coPilot
      ..dual = dual + other.dual
      ..instructor = instructor + other.instructor;
  }
}

/// Content of column 12 (remarks) in the three totals rows.
enum _RemarksCell { certification, signature, coveredBySignature }

class PdfExportService {
  static Future<File> generateLogbook(
    List<FlightWithStats> flights, {
    Map<int, List<CrewMember>> crewByFlight = const {},
    String? pilotName,
    PicNameMode picNameMode = PicNameMode.self,
  }) async {
    final html = _buildLogbookHtml(
      flights,
      crewByFlight: crewByFlight,
      pilotName: pilotName,
      picNameMode: picNameMode,
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

  static String _fmtInt(int n) => n > 0 ? '$n' : '';

  static LogbookFunction _logbookFunction(
    FlightWithStats f,
    Map<int, List<CrewMember>> crewByFlight,
  ) {
    final role = f.flight.pilotRole != null
        ? CrewRole.fromString(f.flight.pilotRole!)
        : CrewRole.pic;
    return LogbookFunction.resolve(role, crewByFlight[f.flight.id] ?? const []);
  }

  static _Totals _calcPageTotals(
    List<FlightWithStats> page,
    Map<int, List<CrewMember>> crewByFlight,
  ) {
    final t = _Totals();
    for (final f in page) {
      final dur = f.duration;
      if (dur == null || dur.isNegative || dur == Duration.zero) continue;

      final engineCount = f.aircraftWithStats?.engineCount ?? 1;
      if (engineCount <= 1) {
        t.se = t.se + dur;
      } else {
        t.me = t.me + dur;
      }

      t.total = t.total + dur;
      t.dayLandings += f.flight.dayLandings ?? 0;
      t.nightLandings += f.flight.nightLandings ?? 0;

      if (f.flight.flightRules == 'IFR') t.ifr = t.ifr + dur;

      switch (_logbookFunction(f, crewByFlight).function) {
        case PilotFunction.pic:
          t.pic = t.pic + dur;
        case PilotFunction.coPilot:
          t.coPilot = t.coPilot + dur;
        case PilotFunction.dual:
          t.dual = t.dual + dur;
        case PilotFunction.instructor:
          t.instructor = t.instructor + dur;
      }
    }
    return t;
  }

  static String _totalsRow(String label, _Totals t, _RemarksCell remarks) {
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
    buf.write('<td>${_fmtDur(t.coPilot)}</td>');
    buf.write('<td>${_fmtDur(t.dual)}</td>');
    buf.write('<td>${_fmtDur(t.instructor)}</td>');
    buf.write('<td></td>'); // FSTD type
    buf.write('<td></td>'); // FSTD time
    switch (remarks) {
      case _RemarksCell.certification:
        buf.write(
          '<td class="text-top text-left bold" style="font-size: 5pt;">I certify that the entries in this log are true.</td>',
        );
      case _RemarksCell.signature:
        buf.write(
          '<td rowspan="2" class="text-top text-left bold" style="font-size: 6.5pt;">PILOT\'S SIGNATURE</td>',
        );
      case _RemarksCell.coveredBySignature:
        // Column 12 is occupied by the signature cell's rowspan above.
        break;
    }
    buf.write('</tr>');
    return buf.toString();
  }

  static String _tableHeader() {
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
    <th colspan="4" class="bold">10</th>
    <th colspan="2" class="bold">11</th>
    <th class="bold">12</th>
  </tr>
  <tr>
    <th rowspan="2">DATE<br>(dd/mm/yy)</th>
    <th colspan="2">DEPARTURE</th>
    <th colspan="2">ARRIVAL</th>
    <th colspan="2">AIRCRAFT</th>
    <th colspan="2">SINGLE-PILOT TIME</th>
    <th rowspan="2">MULTI-PILOT<br>TIME</th>
    <th rowspan="2">TOTAL<br>TIME</th>
    <th rowspan="2">PIC NAME</th>
    <th colspan="2">LANDINGS</th>
    <th colspan="2">OP. COND. TIME</th>
    <th colspan="4">PILOT FUNCTION TIME</th>
    <th colspan="2">FSTD SESSION</th>
    <th rowspan="2">REMARKS AND<br>ENDORSEMENTS</th>
  </tr>
  <tr>
    <th>PLACE</th><th>TIME</th>
    <th>PLACE</th><th>TIME</th>
    <th>TYPE</th><th>REG</th>
    <th>SE</th><th>ME</th>
    <th>DAY</th><th>NIGHT</th>
    <th>NIGHT</th><th>IFR</th>
    <th>PIC</th><th>COP</th><th>DUAL</th><th>INSTR</th>
    <th>TYPE</th><th>TIME</th>
  </tr>
</thead>''';
  }

  static String _buildLogbookHtml(
    List<FlightWithStats> flights, {
    Map<int, List<CrewMember>> crewByFlight = const {},
    String? pilotName,
    PicNameMode picNameMode = PicNameMode.self,
  }) {
    final dateFmt = DateFormat('dd/MM/yy');
    final timeFmt = DateFormat('HH:mm');
    final selfPicName = picNameMode == PicNameMode.self
        ? 'SELF'
        : (pilotName ?? '');

    final pages = <List<FlightWithStats>>[];
    for (var i = 0; i < flights.length; i += _rowsPerPage) {
      pages.add(
        flights.sublist(i, (i + _rowsPerPage).clamp(0, flights.length)),
      );
    }
    if (pages.isEmpty) pages.add([]);

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
  }
  body {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 7.5pt;
    color: black;
  }
  .logbook-page {
    page-break-after: always;
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
    border: 0.2px solid black;
    text-align: center;
    vertical-align: middle;
    padding: 1px 1px;
    box-sizing: border-box;
    word-wrap: break-word;
    overflow: hidden;
  }
  th {
    font-weight: bold;
    font-size: 5pt;
    padding: 8px 1px;
    line-height: 1.1;
  }
  .row-data td {
    height: 5.5mm;
    font-size: 7pt;
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
  .text-top {
    vertical-align: top;
    padding-top: 3px;
  }
  .bg-grey { background-color: #f2f2f2; }
  colgroup col:nth-child(12) { background-color: #fafafa; }
</style>
</head>
<body>
''');

    var prevTotals = _Totals();

    for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final pageFlights = pages[pageIdx];
      final pageTotals = _calcPageTotals(pageFlights, crewByFlight);
      final grandTotals = prevTotals + pageTotals;

      buf.write('<div class="logbook-page">');
      buf.write('<table>');
      buf.write('''
<colgroup>
  <col style="width:5%">
  <col style="width:4%">
  <col style="width:3.5%">
  <col style="width:4%">
  <col style="width:3.5%">
  <col style="width:4.5%">
  <col style="width:4.5%">
  <col style="width:4%">
  <col style="width:4%">
  <col style="width:5%">
  <col style="width:4%">
  <col style="width:6%">
  <col style="width:3%">
  <col style="width:3%">
  <col style="width:3.5%">
  <col style="width:3.5%">
  <col style="width:3.5%">
  <col style="width:3.5%">
  <col style="width:3.5%">
  <col style="width:3.5%">
  <col style="width:5%">
  <col style="width:2.5%">
  <col style="width:13%">
</colgroup>
''');
      buf.write(_tableHeader());
      buf.write('<tbody>');

      for (int i = 0; i < _rowsPerPage; i++) {
        final grey = (i + 1) % 3 == 0 ? ' bg-grey' : '';
        buf.write('<tr class="row-data$grey">');

        if (i < pageFlights.length) {
          final f = pageFlights[i];
          final dur = f.duration;
          final engineCount = f.aircraftWithStats?.engineCount ?? 1;
          final isIfr = f.flight.flightRules == 'IFR';

          final seTime = (dur != null && !dur.isNegative && engineCount <= 1)
              ? _fmtDur(dur)
              : '';
          final meTime = (dur != null && !dur.isNegative && engineCount > 1)
              ? _fmtDur(dur)
              : '';
          final totalTime = (dur != null && !dur.isNegative)
              ? _fmtDur(dur)
              : '';
          final ifrTime = (dur != null && !dur.isNegative && isIfr)
              ? _fmtDur(dur)
              : '';
          final logbook = _logbookFunction(f, crewByFlight);
          final picName = logbook.picPerson != null
              ? _escape(logbook.picPerson!.surname)
              : selfPicName;
          String fnTime(PilotFunction fn) =>
              logbook.function == fn ? totalTime : '';

          final dayLandings = _fmtInt(f.flight.dayLandings ?? 0);
          final nightLandings = _fmtInt(f.flight.nightLandings ?? 0);

          final remarks = f.flight.remarks ?? '';

          buf
            ..write('<td>${dateFmt.format(f.flight.departureTime)}</td>')
            ..write('<td>${f.departure?.ident ?? ''}</td>')
            ..write('<td>${timeFmt.format(f.flight.departureTime)}</td>')
            ..write('<td>${f.arrival?.ident ?? ''}</td>')
            ..write(
              '<td>${f.flight.arrivalTime != null ? timeFmt.format(f.flight.arrivalTime!) : ''}</td>',
            )
            ..write('<td>${f.aircraftWithStats?.designator ?? ''}</td>')
            ..write('<td>${f.aircraftWithStats?.tailNumber ?? ''}</td>')
            ..write('<td>$seTime</td>')
            ..write('<td>$meTime</td>')
            ..write('<td></td>') // multi-pilot
            ..write('<td>$totalTime</td>')
            ..write('<td>$picName</td>')
            ..write('<td>$dayLandings</td>')
            ..write('<td>$nightLandings</td>')
            ..write('<td></td>') // night time
            ..write('<td>$ifrTime</td>')
            ..write('<td>${fnTime(PilotFunction.pic)}</td>')
            ..write('<td>${fnTime(PilotFunction.coPilot)}</td>')
            ..write('<td>${fnTime(PilotFunction.dual)}</td>')
            ..write('<td>${fnTime(PilotFunction.instructor)}</td>')
            ..write('<td></td>') // FSTD type
            ..write('<td></td>') // FSTD time
            ..write('<td class="text-left">$remarks</td>');
        } else {
          for (int j = 0; j < 23; j++) {
            buf.write('<td></td>');
          }
        }

        buf.write('</tr>');
      }

      // Totals rows
      buf.write(
        _totalsRow('TOTAL THIS PAGE', pageTotals, _RemarksCell.certification),
      );
      buf.write(
        _totalsRow(
          'TOTAL FROM PREVIOUS PAGES',
          prevTotals,
          _RemarksCell.signature,
        ),
      );
      buf.write(
        _totalsRow('TOTAL TIME', grandTotals, _RemarksCell.coveredBySignature),
      );

      buf.write('</tbody></table></div>');

      prevTotals = grandTotals;
    }

    buf.write('</body></html>');
    return buf.toString();
  }
}
