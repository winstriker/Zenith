import 'package:flutter/material.dart';

/// Opens [image] full screen on black, with pinch-to-zoom. Tap or swipe down
/// to close. [caption] is shown at the bottom, outside the zoomed area.
void showFullScreenImage(
  BuildContext context,
  Widget image, {
  String? title,
  Widget? caption,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _FullScreenImage(image: image, title: title, caption: caption),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.image, this.title, this.caption});
  final Widget image;
  final String? title;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: title == null ? null : Text(title!),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            Center(child: InteractiveViewer(maxScale: 4, child: image)),
            if (caption != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: caption,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
