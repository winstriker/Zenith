List<List<String>> parseCsv(String data) {
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final currentField = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < data.length; i++) {
    final char = data[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < data.length && data[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        currentField.write(char);
      }
    } else {
      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        currentRow.add(currentField.toString());
        currentField.clear();
      } else if (char == '\n') {
        final field = currentField.toString();
        if (field.isNotEmpty || currentRow.isNotEmpty) {
          currentRow.add(field);
        }
        currentField.clear();
        if (currentRow.isNotEmpty) {
          rows.add(List.from(currentRow));
        }
        currentRow.clear();
      } else if (char != '\r') {
        currentField.write(char);
      }
    }
  }

  final lastField = currentField.toString();
  if (lastField.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(lastField);
    if (currentRow.isNotEmpty) {
      rows.add(List.from(currentRow));
    }
  }

  return rows;
}
