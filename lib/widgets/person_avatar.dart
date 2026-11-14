import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/person_photo_store.dart';

/// Round profile picture, or the first letter of [name] on grey when there is
/// no picture. [file] overrides [photo] (used for a not-yet-saved pick).
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.photo,
    this.file,
    this.radius = 20,
  });

  final String name;

  /// Stored file name (see [PersonPhotoStore]).
  final String? photo;
  final File? file;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    File? image = file;
    if (image == null && photo != null) {
      final dir = ref.watch(personPhotoDirectoryProvider).value;
      if (dir != null) image = File('${dir.path}/$photo');
    }
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.avatar,
      foregroundColor: colors.onAvatar,
      foregroundImage: image != null ? FileImage(image) : null,
      child: Text(
        letter,
        style: TextStyle(fontSize: radius * 0.9, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Opens the stored [photo] full screen, with pinch-to-zoom. Tap or swipe
/// down to close.
void showPersonPhoto(BuildContext context, String photo, {String? title}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _PersonPhotoViewer(photo: photo, title: title),
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

class _PersonPhotoViewer extends ConsumerWidget {
  const _PersonPhotoViewer({required this.photo, this.title});
  final String photo;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(personPhotoDirectoryProvider).value;
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
        child: Center(
          child: dir == null
              ? const CircularProgressIndicator()
              : InteractiveViewer(
                  maxScale: 4,
                  child: Image.file(
                    File('${dir.path}/$photo'),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}
