import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/aircraft_providers.dart';
import '../providers/carto_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/theme_provider.dart';
import '../providers/unit_provider.dart';
import '../providers/user_provider.dart';
import '../services/aircraft_image_cache.dart';
import '../widgets/section_header.dart';
import 'backup_settings_page.dart';
import 'export_page.dart';
import 'people_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _deleteSavedAircraftPhotos() async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved aircraft photos deleted')),
      );
    }
  }

  static String _megabytes(int bytes) {
    if (bytes == 0) return 'Nothing saved';
    final mb = bytes / (1024 * 1024);
    return mb < 0.1
        ? 'Less than 0.1 MB saved'
        : '${mb.toStringAsFixed(1)} MB saved';
  }

  static String _limitLabel(int bytes) {
    if (bytes == 0) return 'Off';
    final mb = bytes ~/ (1024 * 1024);
    return mb >= 1024 && mb % 1024 == 0 ? '${mb ~/ 1024} GB' : '$mb MB';
  }

  Future<void> _chooseAircraftPhotoLimit(int current) async {
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
                              : _limitLabel(choice),
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

  void _clearAllFlights() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Flights'),
        content: const Text(
          'Are you sure you want to delete all recorded flights? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final flightService = ref.read(flightServiceProvider);
              final flightsAsync = ref.read(flightListStreamProvider);
              final sessions = flightsAsync.value?.toList() ?? [];
              for (final s in sessions) {
                await flightService.deleteSession(s.flight.id);
              }
              // Stream provider automatically updates
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _editApiKey(String? currentKey) async {
    final result = await showDialog<_ApiKeyResult>(
      context: context,
      builder: (_) => _ApiKeyDialog(currentKey: currentKey),
    );
    if (result == null) return;
    final notifier = ref.read(cartoApiKeyProvider.notifier);
    switch (result) {
      case _ApiKeyRemove():
        await notifier.clearKey();
      case _ApiKeySave(:final key):
        await notifier.setKey(key);
    }
  }

  Future<void> _reloadAircraftTypes() async {
    try {
      await ref.read(aircraftTypesLoadProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aircraft types reloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reload aircraft types: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final unitMode = ref.watch(unitProvider);
    final cartoKey = ref.watch(cartoApiKeyProvider);
    final picNameMode = ref.watch(picNameModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const SectionHeader(title: 'Preferences', uppercase: true),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeMode == ThemeMode.light
                                ? Icons.light_mode
                                : themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.brightness_auto,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text('Theme', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Light'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Dark'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              icon: Icon(Icons.settings_suggest_outlined),
                              label: Text('Auto'),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (newSelection) {
                            ref
                                .read(themeProvider.notifier)
                                .setThemeMode(newSelection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Measurement Units',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<MeasurementUnit>(
                          segments: const [
                            ButtonSegment<MeasurementUnit>(
                              value: MeasurementUnit.metric,
                              icon: Icon(Icons.speed),
                              label: Text('Metric'),
                            ),
                            ButtonSegment<MeasurementUnit>(
                              value: MeasurementUnit.knots,
                              icon: Icon(Icons.airplanemode_active),
                              label: Text('Knots'),
                            ),
                          ],
                          selected: {unitMode},
                          onSelectionChanged: (newSelection) {
                            ref
                                .read(unitProvider.notifier)
                                .setUnit(newSelection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.map, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Text(
                            'Map API Key',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cartoKey != null
                                  ? '${cartoKey.substring(0, cartoKey.length > 8 ? 8 : cartoKey.length)}...'
                                  : 'Not set',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cartoKey != null
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _editApiKey(cartoKey),
                            child: Text(cartoKey != null ? 'Change' : 'Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'PIC Name in Logbook',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<PicNameMode>(
                          segments: const [
                            ButtonSegment<PicNameMode>(
                              value: PicNameMode.self,
                              icon: Icon(Icons.person_outline),
                              label: Text('SELF'),
                            ),
                            ButtonSegment<PicNameMode>(
                              value: PicNameMode.name,
                              icon: Icon(Icons.badge_outlined),
                              label: Text('Pilot name'),
                            ),
                          ],
                          selected: {picNameMode},
                          onSelectionChanged: (s) => ref
                              .read(picNameModeProvider.notifier)
                              .setMode(s.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Data Management', uppercase: true),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('People'),
                  subtitle: const Text('Manage crew members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const PeoplePage()),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear All Flights'),
                  subtitle: const Text('Delete all recorded flight data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearAllFlights,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('PDF, CSV or Json'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ExportPage()),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reload Aircraft Types'),
                  subtitle: const Text('from ICAO doc. 8643'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _reloadAircraftTypes,
                ),
                const Divider(height: 1, indent: 72),
                Consumer(
                  builder: (context, ref, _) {
                    final limit = ref.watch(aircraftImageCacheLimitProvider);
                    return ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Offline Aircraft Photos'),
                      subtitle: Text(
                        limit == 0
                            ? 'Off · photos need a connection'
                            : 'Keep up to ${_limitLabel(limit)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _chooseAircraftPhotoLimit(limit),
                    );
                  },
                ),
                const Divider(height: 1, indent: 72),
                Consumer(
                  builder: (context, ref, _) {
                    final bytes = ref
                        .watch(aircraftImageCacheSizeProvider)
                        .value;
                    return ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('Delete Saved Photos'),
                      subtitle: Text(
                        bytes == null ? 'Calculating…' : _megabytes(bytes),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: bytes != null && bytes > 0,
                      onTap: _deleteSavedAircraftPhotos,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Backup', uppercase: true),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup Settings'),
              subtitle: const Text('Manage your backups'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BackupSettingsPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'About', uppercase: true),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.flight_takeoff),
                  title: Text("Zenith"),
                  subtitle: Text('Version $appBuildName'),
                ),
                Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Description'),
                  subtitle: Text('Pilot\'s Logbook'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Zenith v$appBuildName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

sealed class _ApiKeyResult {
  const _ApiKeyResult();
}

class _ApiKeySave extends _ApiKeyResult {
  const _ApiKeySave(this.key);
  final String key;
}

class _ApiKeyRemove extends _ApiKeyResult {
  const _ApiKeyRemove();
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.currentKey});
  final String? currentKey;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final _controller = TextEditingController(text: widget.currentKey ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CARTO API Key'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Paste your API key',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentKey != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _ApiKeyRemove()),
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _ApiKeySave(_controller.text)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
