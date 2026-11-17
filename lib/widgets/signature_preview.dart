import 'dart:io';

import 'package:flutter/material.dart';

/// A signature as it fits its box in the exported logbook: on white paper,
/// whatever the theme, with the box's [aspectRatio].
class SignaturePreview extends StatelessWidget {
  const SignaturePreview({
    super.key,
    required this.file,
    required this.aspectRatio,
    this.onTap,
    this.tooltip = 'Change signature',
  });

  final File file;
  final double aspectRatio;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final preview = AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.black38),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return preview;
    return Tooltip(
      message: tooltip,
      child: Stack(
        children: [
          preview,
          // Above the white paper, or the ripple wouldn't show.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, borderRadius: radius),
            ),
          ),
        ],
      ),
    );
  }
}
