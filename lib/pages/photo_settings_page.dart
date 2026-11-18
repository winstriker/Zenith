import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../providers/provider_toggles.dart';
import '../services/aircraft_image_cache.dart';
import '../services/aircraft_lookup_service.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';

/// Where aircraft photos are looked for, and how many of them are kept on
/// the device.
class PhotoSettingsPage extends ConsumerWidget {
  const PhotoSettingsPage({super.key});

  /// "100 MB", "1 GB", or "Off" for 0.
  static String limitLabel(int bytes) {
    if (bytes == 0) return 'Off';
    final mb = bytes ~/ (1024 * 1024);
    return mb >= 1024 && mb % 1024 == 0 ? '${mb ~/ 1024} GB' : '$mb MB';
  }

  static String _megabytes(int bytes) {
    if (bytes == 0) return 'Nothing saved';
    final mb = bytes / (1024 * 1024);
    return mb < 0.1
        ? 'Less than 0.1 MB saved'
        : '${mb.toStringAsFixed(1)} MB saved';
  }

  Future<void> _chooseLimit(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offline Aircraft Photos'),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Photos found online are kept on this device once seen, '
                  'so they show offline too. When the space is full, the '
                  'photos seen longest ago make room.',
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<int>(
                groupValue: current,
                onChanged: (value) => Navigator.pop(ctx, value),
                child: Column(
                  children: [
                    for (final choice in AircraftImageCache.maxBytesChoices)
                      RadioListTile<int>(
                        value: choice,
                        title: Text(
                          choice == 0
                              ? "Don't keep photos"
                              : limitLabel(choice),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (chosen == null || chosen == current) return;
    await ref
        .read(aircraftImageCacheLimitProvider.notifier)
        .setMaxBytes(chosen);
    // Lowering the limit deletes what no longer fits.
    await ref.read(aircraftImageCacheProvider).trim();
    ref.invalidate(aircraftImageCacheSizeProvider);
  }

  Future<void> _deleteSaved(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Saved Photos'),
        content: const Text(
          'Aircraft photos found online are kept on this device after you '
          'see them, so they also show when you are offline. Deleting them '
          'frees the space; they are downloaded again the next time you see '
          'them online. Photos you picked yourself are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(aircraftImageCacheProvider).clear();
    ref.invalidate(aircraftImageCacheSizeProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Saved aircraft photos deleted')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(photoSourcesProvider);
    final off = ref.watch(disabledPhotoSourcesProvider);
    final limit = ref.watch(aircraftImageCacheLimitProvider);
    final saved = ref.watch(aircraftImageCacheSizeProvider).value;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle(
            'Aircraft Photos',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          const SectionHeader(title: 'Photo Providers', uppercase: true),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, source) in sources.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    value: !off.contains(source.id),
                    onChanged: (on) => ref
                        .read(disabledPhotoSourcesProvider.notifier)
                        .setEnabled(source.id, enabled: on),
                    title: Text(source.label),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Offline Photos', uppercase: true),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Offline Aircraft Photos'),
                  subtitle: Text(
                    limit == 0
                        ? 'Off · photos need a connection'
                        : 'Keep up to ${limitLabel(limit)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseLimit(context, ref, limit),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Delete Saved Photos'),
                  subtitle: Text(
                    saved == null ? 'Calculating…' : _megabytes(saved),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: saved != null && saved > 0,
                  onTap: () => _deleteSaved(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
