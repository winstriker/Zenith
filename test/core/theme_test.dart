import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('every palette is readable in light, dark and OLED', () {
    // Palettes, and the system colors from a few wallpaper accents.
    for (final (palette, accent) in [
      for (final p in AppPalette.values) (p, null),
      for (final c in const [Colors.red, Colors.yellow, Colors.green])
        (AppPalette.zenith, c as Color),
    ]) {
      for (final (brightness, oled) in [
        (Brightness.light, false),
        (Brightness.dark, false),
        (Brightness.dark, true),
      ]) {
        final s = AppTheme.scheme(
          brightness,
          palette: palette,
          oled: oled,
          systemAccent: accent,
        );
        final where = '${palette.name} $accent $brightness oled=$oled';
        expect(_contrast(s.onSurface, s.surface), greaterThan(7));
        for (final bg in [s.surface, s.surfaceContainerHighest]) {
          expect(_contrast(s.onSurface, bg), greaterThan(4.5), reason: where);
          expect(
            _contrast(s.onSurfaceVariant, bg),
            greaterThan(4.5),
            reason: where,
          );
          expect(_contrast(s.primary, bg), greaterThan(4.5), reason: where);
        }
        expect(_contrast(s.onPrimary, s.primary), greaterThan(4.5));
        if (oled) expect(s.surface, Colors.black);
      }
    }
  });
}
