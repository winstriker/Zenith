import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/person_photo_store.dart';
import 'full_screen_image.dart';

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
  showFullScreenImage(
    context,
    title: title,
    Consumer(
      builder: (context, ref, _) {
        final dir = ref.watch(personPhotoDirectoryProvider).value;
        return dir == null
            ? const CircularProgressIndicator()
            : Image.file(
                File('${dir.path}/$photo'),
                fit: BoxFit.contain,
                width: double.infinity,
              );
      },
    ),
  );
}
