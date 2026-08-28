import 'dart:io';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'database.dart';

const _rowsPerPage = 20;

class PdfExportService {
  static Future<File> generateLogbook(List<FlightWithStats> flights) async {
    final html = _buildPilotLogbookHtml(flights);

    final converter = HtmlToPdfConverter();

    final directory = await getApplicationDocumentsDirectory();

    final pdfFile = await converter.convertHtmlToPdf(
      html: html,
      targetDirectory: directory.path,
      targetName: 'logbook_export',
      pageSize: PdfPageSize.a4.landscape,
    );

    return pdfFile;
  }

  static String _buildPilotLogbookHtml(List<FlightWithStats> flights) {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('dd/MM/yy');
    final timeFmt = DateFormat('HH:mm');

    buffer.write('''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">

<style>
    @page {
        size: A4 landscape;
        margin: 8mm;
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
        padding: 10px 1px;
        line-height: 1.1;
    }

    .bold {
        font-weight: bold;
    }

    .row-data td {
        height: 6mm;
    }

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

    .bg-grey {
        background-color: #f2f2f2;
    }
</style>
</head>

<body>

<table>

<colgroup>
    <col style="width: 5%;">
    <col style="width: 4%;">
    <col style="width: 3.5%;">
    <col style="width: 4%;">
    <col style="width: 3.5%;">
    <col style="width: 4.5%;">
    <col style="width: 4.5%;">
    <col style="width: 4%;">
    <col style="width: 4%;">
    <col style="width: 5%;">
    <col style="width: 4%;">
    <col style="width: 6%;">
    <col style="width: 3%;">
    <col style="width: 3%;">
    <col style="width: 3.5%;">
    <col style="width: 3.5%;">
    <col style="width: 3.5%;">
    <col style="width: 3.5%;">
    <col style="width: 3.5%;">
    <col style="width: 3.5%;">
    <col style="width: 5%;">
    <col style="width: 2.5%;">
    <col style="width: 13%;">
</colgroup>

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
        <th>PLACE</th>
        <th>TIME</th>
        <th>PLACE</th>
        <th>TIME</th>
        <th>TYPE</th>
        <th>REG</th>
        <th>SE</th>
        <th>ME</th>
        <th>DAY</th>
        <th>NIGHT</th>
        <th>NIGHT</th>
        <th>IFR</th>
        <th>PIC</th>
        <th>COP</th>
        <th>DUAL</th>
        <th>INSTR</th>
        <th>TYPE</th>
        <th>TIME</th>
    </tr>
</thead>

<tbody>
''');

    final pages = <List<FlightWithStats>>[];
    for (var i = 0; i < flights.length; i += _rowsPerPage) {
      pages.add(
        flights.sublist(i, (i + _rowsPerPage).clamp(0, flights.length)),
      );
    }
    if (pages.isEmpty) pages.add([]);

    for (final pageFlights in pages) {
      for (int i = 0; i < _rowsPerPage; i++) {
        final grey = (i + 1) % 3 == 0 ? ' bg-grey' : '';

        buffer.write('<tr class="row-data$grey">');

        if (i < pageFlights.length) {
          final flight = pageFlights[i];
          final date = dateFmt.format(flight.flight.departureTime);
          final depPlace = flight.departureIdent ?? '';
          final depTime = timeFmt.format(flight.flight.departureTime);
          final arrPlace = flight.arrivalIdent ?? '';
          final arrTime = flight.flight.arrivalTime != null
              ? timeFmt.format(flight.flight.arrivalTime!)
              : '';
          final acftType = flight.aircraft?.type ?? '';
          final acftReg = flight.aircraft?.tailNumber ?? '';
          final total = flight.duration != null
              ? '${flight.duration!.inHours.toString().padLeft(2, '0')}:${(flight.duration!.inMinutes % 60).toString().padLeft(2, '0')}'
              : '';
          final remarks = flight.flight.title ?? '';

          buffer.write('<td>$date</td>');
          buffer.write('<td>$depPlace</td>');
          buffer.write('<td>$depTime</td>');
          buffer.write('<td>$arrPlace</td>');
          buffer.write('<td>$arrTime</td>');
          buffer.write('<td>$acftType</td>');
          buffer.write('<td>$acftReg</td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td>$total</td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td></td>');
          buffer.write('<td>$remarks</td>');
        } else {
          for (int j = 0; j < 23; j++) {
            buffer.write('<td></td>');
          }
        }

        buffer.write('</tr>');
      }
    }

    buffer.write('''
<tr class="row-data">
    <td colspan="7" class="text-right">TOTAL THIS PAGE</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td class="text-top text-left bold" style="font-size: 5pt;">
        I certify that the entries in this log are true.
    </td>
</tr>

<tr class="row-data">
    <td colspan="7" class="text-right">TOTAL FROM PREVIOUS PAGES</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td rowspan="3"
        class="text-top text-left bold"
        style="font-size: 6.5pt;">
        PILOT'S SIGNATURE
    </td>
</tr>

<tr class="row-data">
    <td colspan="7" class="text-right">TOTAL TIME</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
</tr>

</tbody>
</table>

</body>
</html>
''');

    return buffer.toString();
  }
}
