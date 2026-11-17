import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Ink of the signature, as from a blue pen.
const _ink = Color(0xFF1A237E);
const _strokeWidth = 3.0;

/// Longest side of the saved image, in pixels.
const _maxOutputSide = 1200.0;

/// Lets the user sign with a finger. Pops a PNG (transparent background,
/// trimmed to the ink) in the temporary folder, or null when cancelled.
class SignaturePadPage extends StatefulWidget {
  const SignaturePadPage({super.key});

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  final _strokes = <List<Offset>>[];
  bool _saving = false;

  void _start(Offset point) => setState(() => _strokes.add([point]));

  void _extend(Offset point) => setState(() => _strokes.last.add(point));

  void _undo() => setState(_strokes.removeLast);

  void _clear() => setState(_strokes.clear);

  Future<void> _done() async {
    setState(() => _saving = true);
    try {
      final file = await _export();
      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save signature: $e')));
    }
  }

  /// Draws the strokes, cropped to the ink, into a PNG file.
  Future<File> _export() async {
    var bounds = _strokes
        .expand((s) => s)
        .map((p) => Rect.fromCircle(center: p, radius: _strokeWidth))
        .reduce((a, b) => a.expandToInclude(b));
    bounds = bounds.inflate(_strokeWidth * 2);
    final scale = math.min(
      3.0,
      _maxOutputSide / math.max(bounds.width, bounds.height),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    _SignaturePainter.paintStrokes(canvas, _strokes);
    final image = await recorder.endRecording().toImage(
      (bounds.width * scale).ceil(),
      (bounds.height * scale).ceil(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File(
      '${Directory.systemTemp.path}/signature_${const Uuid().v4()}.png',
    );
    await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final empty = _strokes.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw signature'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: empty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: empty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3,
                    child: DecoratedBox(
                      // Paper is white whatever the theme.
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Ink off the pad would be saved but not seen.
                            Offset inside(Offset p) => Offset(
                              p.dx.clamp(0, constraints.maxWidth),
                              p.dy.clamp(0, constraints.maxHeight),
                            );
                            return GestureDetector(
                              // Start the line where the finger went down,
                              // not where the drag was recognised.
                              dragStartBehavior: DragStartBehavior.down,
                              onPanStart: (d) =>
                                  _start(inside(d.localPosition)),
                              onPanUpdate: (d) =>
                                  _extend(inside(d.localPosition)),
                              // A tap leaves a dot.
                              onTapUp: (d) => _start(inside(d.localPosition)),
                              child: CustomPaint(
                                painter: _SignaturePainter(_strokes),
                                child: const SizedBox.expand(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: empty || _saving ? null : _done,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  static void paintStrokes(Canvas canvas, List<List<Offset>> strokes) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          _strokeWidth / 2,
          Paint()..color = _ink,
        );
        continue;
      }
      // Through the midpoints, so the line comes out smooth.
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length - 1; i++) {
        final mid = (stroke[i] + stroke[i + 1]) / 2;
        path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Where to sign.
    final y = size.height * 0.75;
    canvas.drawLine(
      Offset(size.width * 0.06, y),
      Offset(size.width * 0.94, y),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1,
    );
    paintStrokes(canvas, strokes);
  }

  // The strokes list is changed in place.
  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
