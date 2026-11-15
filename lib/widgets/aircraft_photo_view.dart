import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/aircraft_photo.dart';
import '../services/aircraft_image_cache.dart';
import '../services/person_photo_store.dart';

/// Width over height of the frames aircraft photos are shown in. Spotting
/// sites center the aircraft, so a centered crop of a wider shot (e.g. 16:9)
/// keeps nose and tail in the frame.
const aircraftPhotoAspectRatio = 3 / 2;

/// Shows the photo of an aircraft, filling the space it is given, or
/// [placeholder] when there is no photo or it can't be loaded.
///
/// Online photos go through [AircraftImageCache]: once shown, a photo is
/// shown again without a connection.
class AircraftPhotoView extends ConsumerWidget {
  const AircraftPhotoView({
    super.key,
    required this.photo,
    required this.placeholder,
    this.pickedFile,
    this.thumbnail = false,
  });

  final AircraftPhoto? photo;

  /// A picture the user just picked and that is not stored yet. Shown
  /// instead of [photo].
  final File? pickedFile;

  /// Use the small version of an online photo and decode files at a small
  /// size. For lists.
  final bool thumbnail;
  final Widget placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheWidth = thumbnail ? 400 : null;
    var file = pickedFile;
    final stored = photo?.file;
    if (file == null && stored != null) {
      final dir = ref.watch(aircraftPhotoDirectoryProvider).value;
      if (dir == null) return placeholder;
      file = File('${dir.path}/$stored');
    }

    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    final url = thumbnail ? photo?.thumbnailUrl : photo?.url;
    if (url == null) return placeholder;
    return Image(
      image: ResizeImage.resizeIfNeeded(
        cacheWidth,
        null,
        CachedAircraftImage(url, ref.watch(aircraftImageCacheProvider)),
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      // The placeholder stays until the picture has arrived, then fades out.
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// Who took an online photo and where it comes from, on a dark pill to stay
/// readable on any picture. Opens the photo's page when tapped, unless
/// [small].
class AircraftPhotoCredit extends StatelessWidget {
  const AircraftPhotoCredit({
    super.key,
    required this.photo,
    this.small = false,
  });
  final AircraftPhoto photo;

  /// A smaller pill that doesn't open the photo's page, for photos in lists
  /// where a tap belongs to the item.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final link = small || photo.link == null ? null : Uri.tryParse(photo.link!);
    final credit = photo.credit;
    final label = [if (credit != null) '© $credit', ?photo.source].join(' · ');
    if (label.isEmpty) return const SizedBox.shrink();

    return Material(
      color: colors.overlay.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(small ? 2 : 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: link == null
            ? null
            : () => launchUrl(link, mode: LaunchMode.externalApplication),
        child: Padding(
          padding: small
              ? const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onOverlay,
                    fontSize: small ? 6 : null,
                    height: small ? 1.1 : null,
                  ),
                ),
              ),
              if (link != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 12, color: colors.onOverlay),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The gradient shown at the top of aircraft pages when there is no photo.
class AircraftHeaderGradient extends StatelessWidget {
  const AircraftHeaderGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.secondaryContainer,
            cs.secondaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
