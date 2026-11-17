import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zenith/pages/image_crop_page.dart';

/// A [width] x [height] opaque red PNG.
Uint8List _redPng(int width, int height) => img.encodePng(
  img.Image(width: width, height: height)
    ..clear(img.ColorRgba8(255, 0, 0, 255)),
);

void main() {
  /// Opens the cropper on [bytes], taps Done and returns what it popped.
  Future<File?> crop(WidgetTester tester, Uint8List bytes, CropSpec spec) =>
      tester.runAsync<File?>(() async {
        File? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageCropPage(bytes: bytes, spec: spec),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        // Not pumpAndSettle: the spinner never settles.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Decoding happens off the test clock.
        for (var i = 0; i < 50 && find.text('Done').evaluate().isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        for (var i = 0; i < 50; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          final done = tester.widget<FilledButton>(
            find.ancestor(
              of: find.text('Done'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          );
          if (done.onPressed != null) break;
        }
        await tester.tap(find.text('Done'));
        for (var i = 0; i < 100 && result == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        return result;
      });

  testWidgets('outside the picture comes out transparent', (tester) async {
    final file = await crop(
      tester,
      _redPng(200, 100),
      const CropSpec(
        title: 'Fit',
        aspectRatio: 20 / 3,
        outputWidth: 600,
        allowOutside: true,
      ),
    );
    expect(file, isNotNull);
    expect(file!.path, endsWith('.png'));
    final out = img.decodePng(file.readAsBytesSync())!;
    // The frame starts as wide as the picture: 200 pixels across.
    expect((out.width, out.height), (200, 30));
    final center = out.getPixel(100, 15);
    expect((center.r, center.a), (255, 255));
  });

  testWidgets('a picture smaller than the frame leaves transparency', (
    tester,
  ) async {
    // Flatter than the frame: as wide as it, with gaps above and below.
    final file = await crop(
      tester,
      _redPng(300, 20),
      const CropSpec(
        title: 'Fit',
        aspectRatio: 20 / 3,
        outputWidth: 600,
        allowOutside: true,
      ),
    );
    final out = img.decodePng(file!.readAsBytesSync())!;
    expect((out.width, out.height), (300, 45));
    expect(out.getPixel(150, 0).a, 0);
    expect(out.getPixel(150, 44).a, 0);
    expect(out.getPixel(150, 22).a, 255);
  });

  testWidgets('an opaque crop fills the frame and is a JPEG', (tester) async {
    final file = await crop(
      tester,
      _redPng(200, 100),
      const CropSpec(
        title: 'Crop',
        aspectRatio: 1,
        outputWidth: 512,
        circle: true,
        jpegQuality: 80,
      ),
    );
    expect(file, isNotNull);
    expect(file!.path, endsWith('.jpg'));
    final out = img.decodeJpg(file.readAsBytesSync())!;
    // The frame holds 100 x 100 pixels of the picture: no upscaling.
    expect((out.width, out.height), (100, 100));
    expect(out.getPixel(0, 0).r, greaterThan(200));
    expect(out.getPixel(99, 99).r, greaterThan(200));
  });
}
