const _quote = 0x22; // "
const _comma = 0x2C; // ,
const _lf = 0x0A; // \n
const _cr = 0x0D; // \r

/// Parses RFC 4180-style CSV.
///
/// Works on UTF-16 code units and slices unquoted fields straight out of
/// [data] with `substring`, only falling back to a [StringBuffer] for fields
/// that contain quotes or stray carriage returns. Blank lines are skipped and
/// `\r` outside quotes is ignored.
List<List<String>> parseCsv(String data) {
  final rows = <List<String>>[];
  final n = data.length;
  var row = <String>[];
  StringBuffer? buffer; // non-null only when the field needs assembling
  var segmentStart = 0; // start of the raw slice not yet copied
  var inQuotes = false;

  String takeField(int end) {
    final b = buffer;
    if (b == null) return data.substring(segmentStart, end);
    b.write(data.substring(segmentStart, end));
    buffer = null;
    return b.toString();
  }

  var i = 0;
  while (i < n) {
    final c = data.codeUnitAt(i);
    if (inQuotes) {
      if (c == _quote) {
        if (i + 1 < n && data.codeUnitAt(i + 1) == _quote) {
          // Escaped quote: keep one of the two.
          buffer!.write(data.substring(segmentStart, i + 1));
          i += 2;
          segmentStart = i;
          continue;
        }
        buffer!.write(data.substring(segmentStart, i));
        inQuotes = false;
        segmentStart = i + 1;
      }
    } else if (c == _comma) {
      row.add(takeField(i));
      segmentStart = i + 1;
    } else if (c == _lf) {
      final field = takeField(i);
      if (field.isNotEmpty || row.isNotEmpty) {
        row.add(field);
        rows.add(row);
        row = <String>[];
      }
      segmentStart = i + 1;
    } else if (c == _quote) {
      (buffer ??= StringBuffer()).write(data.substring(segmentStart, i));
      inQuotes = true;
      segmentStart = i + 1;
    } else if (c == _cr) {
      (buffer ??= StringBuffer()).write(data.substring(segmentStart, i));
      segmentStart = i + 1;
    }
    i++;
  }

  if (inQuotes) buffer!.write(data.substring(segmentStart, n));
  final lastField = inQuotes ? buffer!.toString() : takeField(n);
  if (lastField.isNotEmpty || row.isNotEmpty) {
    row.add(lastField);
    rows.add(row);
  }

  return rows;
}
