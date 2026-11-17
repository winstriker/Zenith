import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// What a crop produces, and how the user may frame it.
class CropSpec {
  const CropSpec({
    required this.title,
    required this.aspectRatio,
    required this.outputWidth,
    this.circle = false,
    this.allowOutside = false,
    this.jpegQuality,
  });

  final String title;

  /// Width over height of the result.
  final double aspectRatio;

  /// Width of the result, in pixels. Less when the cropped part of the
  /// picture has fewer pixels than that.
  final int outputWidth;

  /// Shows a round frame (the result is still square).
  final bool circle;

  /// Whether the picture may be moved past the frame, or made smaller than
  /// it. What it doesn't cover comes out transparent, so the result is a
  /// PNG.
  final bool allowOutside;

  /// JPEG quality of the result; null for a PNG. Ignored when
  /// [allowOutside], which needs the transparency.
  final int? jpegQuality;

  bool get isPng => allowOutside || jpegQuality == null;
}

/// Picks a picture from [source] and lets the user crop it as [spec] says.
/// Returns the result in the temporary folder, or null when cancelled.
///
/// [maxPickSize] has the picker scale the picture down first; null keeps
/// the original file (and so the transparency of a PNG).
Future<File?> pickAndCropImage(
  BuildContext context, {
  required ImageSource source,
  required CropSpec spec,
  double? maxPickSize = 3000,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: maxPickSize,
    maxHeight: maxPickSize,
  );
  if (picked == null) return null;
  // Read now: image_picker reuses its cache file names, so the file can be
  // replaced by a later pick.
  final bytes = await picked.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.push<File>(
    context,
    MaterialPageRoute(
      builder: (_) => ImageCropPage(bytes: bytes, spec: spec),
    ),
  );
}

Uint8List _encodeJpg(
  ({Uint8List rgba, int width, int height, int quality}) raw,
) => img.encodeJpg(
  img.Image.fromBytes(
    width: raw.width,
    height: raw.height,
    bytes: raw.rgba.buffer,
    numChannels: 4,
  ),
  quality: raw.quality,
);

/// Longest side a picture is decoded at: plenty to crop into, and keeps a
/// huge upload from filling the memory.
const _maxDecodeSide = 3000;

/// Lets the user frame [bytes] by pinching and dragging, then pops the
/// cropped picture as a file in the temporary folder.
class ImageCropPage extends StatefulWidget {
  const ImageCropPage({super.key, required this.bytes, required this.spec});
  final Uint8List bytes;
  final CropSpec spec;

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  ui.Image? _image;
  Object? _error;
  bool _saving = false;

  // Where the picture is, in frame widths from the frame's top left corner,
  // so it doesn't depend on the screen: its left/top edge, and its width.
  Offset _pos = Offset.zero;
  double _zoom = 1;

  // The gesture in progress.
  Offset _startPos = Offset.zero;
  double _startZoom = 1;
  Offset _startFocal = Offset.zero;

  CropSpec get _spec => widget.spec;

  /// Frame height in frame widths.
  double get _frameHeight => 1 / _spec.aspectRatio;

  /// Picture height over width.
  double get _imageRatio => _image!.height / _image!.width;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(widget.bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale = math.min(
        1.0,
        _maxDecodeSide / math.max(descriptor.width, descriptor.height),
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
      _reset();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Zoom at which the picture just fits in the frame.
  double get _containZoom => math.min(1, _frameHeight / _imageRatio);

  /// Zoom at which the picture just covers the frame.
  double get _coverZoom => math.max(1, _frameHeight / _imageRatio);

  double get _minZoom => _spec.allowOutside ? _containZoom / 4 : _coverZoom;

  /// Down to a 50 pixel wide crop of the picture.
  double get _maxZoom => math.max(_minZoom * 4, _image!.width / 50);

  /// The frame as wide as the picture, centered on it. When the picture may
  /// not go past the frame, it fills it instead.
  void _reset() {
    final zoom = _spec.allowOutside ? 1.0 : _coverZoom;
    setState(() {
      _zoom = zoom;
      _pos = Offset((1 - zoom) / 2, (_frameHeight - zoom * _imageRatio) / 2);
    });
  }

  /// Keeps the picture over the whole frame, unless it may go past it.
  Offset _constrain(Offset pos, double zoom) {
    if (_spec.allowOutside) return pos;
    // min(): rounding can put the bound a hair past zero at cover zoom.
    return Offset(
      pos.dx.clamp(math.min(1 - zoom, 0), 0),
      pos.dy.clamp(math.min(_frameHeight - zoom * _imageRatio, 0), 0),
    );
  }

  Future<void> _rotate() async {
    final image = _image!;
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..translate(image.height.toDouble(), 0)
      ..rotate(math.pi / 2)
      ..drawImage(image, Offset.zero, Paint());
    final rotated = await recorder.endRecording().toImage(
      image.height,
      image.width,
    );
    if (!mounted) {
      rotated.dispose();
      return;
    }
    setState(() => _image = rotated);
    image.dispose();
    _reset();
  }

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
      ).showSnackBar(SnackBar(content: Text('Could not crop: $e')));
    }
  }

  Future<File> _export() async {
    final image = _image!;
    // No more pixels than the frame holds of the picture.
    final across = image.width / _zoom;
    final width = math.max(16, math.min(_spec.outputWidth, across.round()));
    final height = math.max(1, (width / _spec.aspectRatio).round());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (!_spec.isPng) {
      canvas.drawColor(Colors.white, BlendMode.src);
    }
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        _pos.dx * width,
        _pos.dy * width,
        _zoom * width,
        _zoom * width * _imageRatio,
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
    final result = await recorder.endRecording().toImage(width, height);
    final Uint8List bytes;
    try {
      if (_spec.isPng) {
        final png = await result.toByteData(format: ui.ImageByteFormat.png);
        bytes = png!.buffer.asUint8List();
      } else {
        final rgba = await result.toByteData();
        // Pure Dart: keep it off the UI.
        bytes = await compute(_encodeJpg, (
          rgba: rgba!.buffer.asUint8List(),
          width: width,
          height: height,
          quality: _spec.jpegQuality!,
        ));
      }
    } finally {
      result.dispose();
    }

    final ext = _spec.isPng ? 'png' : 'jpg';
    final file = File(
      '${Directory.systemTemp.path}/crop_${const Uuid().v4()}.$ext',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final ready = _image != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_spec.title),
        actions: [
          IconButton(
            tooltip: 'Rotate',
            onPressed: ready && !_saving ? _rotate : null,
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: ready && !_saving ? _reset : null,
            icon: const Icon(Icons.fit_screen_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCropArea()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: ready && !_saving ? _done : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    if (_error != null) {
      return const Center(
        child: Text(
          'Could not open this picture.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const margin = 24.0;
        final size = constraints.biggest;
        final frameWidth = math.min(
          size.width - 2 * margin,
          (size.height - 2 * margin) * _spec.aspectRatio,
        );
        final frame = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: frameWidth,
          height: frameWidth / _spec.aspectRatio,
        );
        Offset inFrame(Offset p) => (p - frame.topLeft) / frame.width;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) {
            _startPos = _pos;
            _startZoom = _zoom;
            _startFocal = inFrame(d.localFocalPoint);
          },
          onScaleUpdate: (d) {
            final zoom = (_startZoom * d.scale).clamp(_minZoom, _maxZoom);
            // The point of the picture under the fingers stays under them.
            final anchor = (_startFocal - _startPos) / _startZoom;
            final pos = inFrame(d.localFocalPoint) - anchor * zoom;
            setState(() {
              _zoom = zoom;
              _pos = _constrain(pos, zoom);
            });
          },
          onDoubleTap: _reset,
          child: CustomPaint(
            size: size,
            painter: _CropPainter(
              image: image,
              frame: frame,
              imageRect: Rect.fromLTWH(
                frame.left + _pos.dx * frame.width,
                frame.top + _pos.dy * frame.width,
                _zoom * frame.width,
                _zoom * frame.width * _imageRatio,
              ),
              circle: _spec.circle,
              transparent: _spec.allowOutside,
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.image,
    required this.frame,
    required this.imageRect,
    required this.circle,
    required this.transparent,
  });

  final ui.Image image;
  final Rect frame;
  final Rect imageRect;
  final bool circle;

  /// Whether what the picture doesn't cover comes out transparent: shown as
  /// a checkerboard.
  final bool transparent;

  @override
  void paint(Canvas canvas, Size size) {
    if (transparent) _paintCheckerboard(canvas);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    final frameShape = Path();
    if (circle) {
      frameShape.addOval(frame);
    } else {
      frameShape.addRect(frame);
    }
    // Dim what is cut off.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addPath(frameShape, Offset.zero),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    canvas.drawPath(
      frameShape,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintCheckerboard(Canvas canvas) {
    const cell = 10.0;
    canvas.save();
    canvas.clipRect(frame);
    canvas.drawRect(frame, Paint()..color = Colors.white);
    final grey = Paint()..color = const Color(0xFFDDDDDD);
    for (var y = frame.top; y < frame.bottom; y += cell) {
      for (var x = frame.left; x < frame.right; x += cell) {
        final odd =
            (((x - frame.left) / cell).round() +
                    ((y - frame.top) / cell).round())
                .isOdd;
        if (odd) canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), grey);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image ||
      old.frame != frame ||
      old.imageRect != imageRect ||
      old.circle != circle ||
      old.transparent != transparent;
}
