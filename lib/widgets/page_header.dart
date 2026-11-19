import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/image_crop_page.dart';
import '../providers/header_image_provider.dart';
import '../providers/navigation_provider.dart';

/// Draws the faint motif in a header's gradient, at [size] in [color].
typedef HeaderMotif = Widget Function(double size, Color color);

/// [HeaderMotif] of a single icon.
HeaderMotif iconMotif(IconData icon) =>
    (size, color) => Icon(icon, size: size, color: color);

enum _HeaderImageAction { gallery, camera, remove }

/// A tab's banner: a tall app bar that scrolls away, with the title at its
/// bottom-left. Shows the picture the user picked for [tab], if any, faded
/// into the page towards the bottom so the title reads on any picture;
/// otherwise a gradient of the theme colors with [motif] on it. A sliver, so
/// it goes first in a [CustomScrollView], under a [StatusBarScrim].
class PageHeader extends ConsumerWidget {
  const PageHeader(
    this.title, {
    super.key,
    required this.tab,
    required this.motif,
    this.overline,
    this.trailing,
  });

  final String title;
  final MainTab tab;
  final HeaderMotif motif;

  /// Smaller line above the title.
  final String? overline;

  /// Shown before the change-picture button, e.g. an icon button.
  final Widget? trailing;

  static const expandedHeight = 200.0;

  Future<void> _changeImage(
    BuildContext context,
    WidgetRef ref, {
    required bool hasImage,
  }) async {
    final action = await showModalBottomSheet<_HeaderImageAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _HeaderImageAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _HeaderImageAction.camera),
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove image',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, _HeaderImageAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final notifier = ref.read(headerImageProvider(tab).notifier);
    if (action == _HeaderImageAction.remove) {
      await notifier.remove();
      return;
    }
    // Framed like the expanded header, status bar included.
    final width = MediaQuery.sizeOf(context).width;
    final height = expandedHeight + MediaQuery.paddingOf(context).top;
    final cropped = await pickAndCropImage(
      context,
      source: action == _HeaderImageAction.gallery
          ? ImageSource.gallery
          : ImageSource.camera,
      spec: CropSpec(
        title: 'Crop header image',
        aspectRatio: width / height,
        outputWidth: 1440,
        jpegQuality: 85,
      ),
    );
    if (cropped == null) return;
    await notifier.set(cropped);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final image = ref.watch(headerImageProvider(tab));
    final hasImage = image != null;
    final background = theme.scaffoldBackgroundColor;
    // The text sits on the faded page background, picture or not.
    final foreground = cs.onSurface;
    final overline = this.overline;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      // Scrolls away entirely; StatusBarScrim takes over the status bar.
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.file(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: background),
              )
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.8),
                      cs.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -40,
                child: motif(180, cs.onPrimary.withValues(alpha: 0.1)),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: motif(120, cs.onPrimary.withValues(alpha: 0.08)),
              ),
            ],
            // Fades from the page background at the bottom to mostly the
            // picture (or colors) at the top, like Saikou's home banner.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [background, background.withValues(alpha: 0.24)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                60,
                trailing == null ? 56 : 104,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (overline != null) ...[
                    Text(
                      overline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  ?trailing,
                  IconButton(
                    tooltip: hasImage
                        ? 'Change header image'
                        : 'Add header image',
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: foreground,
                      backgroundColor: foreground.withValues(alpha: 0.12),
                    ),
                    onPressed: () =>
                        _changeImage(context, ref, hasImage: hasImage),
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Once a [PageHeader] has scrolled away, covers the status bar with the
/// page background, so the content doesn't scroll under the clock and
/// icons. Follows the vertical scroll view directly inside [child], fading
/// in over the last few pixels before it reaches the header's height.
class StatusBarScrim extends StatefulWidget {
  const StatusBarScrim({super.key, required this.child});

  final Widget child;

  @override
  State<StatusBarScrim> createState() => _StatusBarScrimState();
}

class _StatusBarScrimState extends State<StatusBarScrim> {
  final _offset = ValueNotifier(0.0);

  static const _showFrom = PageHeader.expandedHeight;
  static const _fadeDistance = 24.0;

  /// Soft edge under the status bar, so cards fade out rather than being
  /// cut by a line.
  static const _edge = 16.0;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final top = MediaQuery.paddingOf(context).top;
    final dark = theme.brightness == Brightness.dark;
    final overlay = dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
              _offset.value = n.metrics.pixels;
            }
            return false;
          },
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + _edge,
          child: IgnorePointer(
            child: ValueListenableBuilder(
              valueListenable: _offset,
              builder: (context, offset, scrim) {
                final t =
                    ((offset - (_showFrom - _fadeDistance)) / _fadeDistance)
                        .clamp(0.0, 1.0);
                // Status bar icons for the page, once the header (which
                // sets them for itself) is gone.
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlay.copyWith(statusBarColor: Colors.transparent),
                  sized: false,
                  child: Opacity(opacity: t, child: scrim),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      background,
                      background,
                      background.withValues(alpha: 0),
                    ],
                    stops: [0, top / (top + _edge), 1],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
