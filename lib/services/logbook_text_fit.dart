import 'dart:math';

/// How a text is set in a cell of the exported logbook: its font size and
/// how many lines it takes.
class FittedText {
  const FittedText(this.text, {required this.points, required this.lines});

  final String text;
  final double points;
  final int lines;

  /// Height of the text, without the cell's padding.
  double get heightMm => lines * LogbookTextFit.lineHeightMm(points);

  /// Whether it has to wrap onto more lines than one.
  bool get wraps => lines > 1;
}

/// Makes text fit the cells of the exported logbook: it is set smaller
/// first, down to a smallest readable size, and only then wrapped onto as
/// many lines as it needs, the row growing taller to hold them. Nothing is
/// ever cut off.
///
/// Widths are estimated from Arial's metrics (the PDF is printed with
/// Arial, or a font of the same widths), with a safety margin: the
/// estimate errs on the wide side, so text set on one line does fit on one
/// line.
abstract final class LogbookTextFit {
  /// Line height, as set in the PDF's CSS, in ems.
  static const lineHeight = 1.15;

  /// The smallest size the PDF is printed at. Android's WebView, which
  /// prints it, never sets text smaller than its minimum font size (8 CSS
  /// pixels, 6 pt): smaller sizes would print larger than planned, and
  /// overflow.
  static const minPrintablePoints = 6.0;

  static const _mmPerPoint = 25.4 / 72;

  /// Room for text in a row of the default height (5.5 mm, less the cell's
  /// padding).
  static const rowTextHeightMm = 4.8;

  /// Over-estimates the widths a little, for the renderer's font.
  static const _safety = 1.1;

  static double lineHeightMm(double points) =>
      points * _mmPerPoint * lineHeight;

  /// Width of [text] at [points], in millimetres.
  static double widthMm(String text, double points) {
    var em = 0.0;
    for (final rune in text.runes) {
      em += _charEm(String.fromCharCode(rune));
    }
    return em * points * _mmPerPoint * _safety;
  }

  static double _charEm(String c) {
    if ('iIl.,:;|!\'`'.contains(c)) return 0.28;
    if (' fjrt-()[]/'.contains(c)) return 0.34;
    if ('mwMW@%'.contains(c)) return 0.88;
    final unit = c.codeUnitAt(0);
    bool between(String a, String b) =>
        unit >= a.codeUnitAt(0) && unit <= b.codeUnitAt(0);
    if (between('0', '9')) return 0.56;
    if (between('A', 'Z')) return 0.70;
    if (between('a', 'z')) return 0.54;
    return 0.62;
  }

  /// Lines [text] takes wrapped in [widthMm] at [points]: words go on the
  /// line while they fit, and a word longer than a line is broken (the CSS
  /// does the same with `overflow-wrap: anywhere`).
  static int linesFor(String text, double points, double widthMm) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 1;
    final space = LogbookTextFit.widthMm(' ', points);
    var lines = 1;
    var used = 0.0;
    for (final word in words) {
      final w = LogbookTextFit.widthMm(word, points);
      if (used > 0 && used + space + w <= widthMm) {
        used += space + w;
        continue;
      }
      if (used > 0) lines++;
      if (w <= widthMm) {
        used = w;
        continue;
      }
      // Broken over as many lines as it needs.
      final extra = (w / widthMm).ceil() - 1;
      lines += extra;
      used = w - extra * widthMm;
    }
    return lines;
  }

  /// [text] at the largest size from [maxPoints] down to [minPoints] at
  /// which it fits in [widthMm] on at most [maxLines] lines no taller than
  /// [heightMm]; failing that, at [minPoints] on as many lines as it needs.
  /// Sizes below [minPrintablePoints] are never used.
  static FittedText fit(
    String text, {
    required double widthMm,
    double maxPoints = 7,
    double minPoints = minPrintablePoints,
    int maxLines = 1,
    double heightMm = rowTextHeightMm,
  }) {
    final smallest = max(minPoints, minPrintablePoints);
    final largest = max(maxPoints, smallest);
    for (var pt = largest; pt >= smallest - 1e-9; pt -= 0.25) {
      final lines = linesFor(text, pt, widthMm);
      final fitLines = max(1, (heightMm / lineHeightMm(pt)).floor());
      if (lines <= min(maxLines, fitLines)) {
        return FittedText(text, points: pt, lines: lines);
      }
    }
    return FittedText(
      text,
      points: smallest,
      lines: linesFor(text, smallest, widthMm),
    );
  }
}
