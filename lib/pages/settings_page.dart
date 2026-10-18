import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/aircraft_providers.dart';
import '../providers/backup_providers.dart';
import '../providers/carto_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/theme_provider.dart';
import '../providers/unit_provider.dart';
import '../services/pdf_export_service.dart';
import '../widgets/section_header.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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

  void _exportData() async {
    final flightsAsync = ref.read(flightListStreamProvider);
    final flights = flightsAsync.value ?? [];
    if (flights.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No flights to export')));
      return;
    }

    try {
      final file = await PdfExportService.generateLogbook(flights);
      await _shareFile(file.path, text: 'Logbook export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _editApiKey(String? currentKey) {
    final controller = TextEditingController(text: currentKey ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CARTO API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste your API key',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (currentKey != null)
            TextButton(
              onPressed: () {
                ref.read(cartoApiKeyProvider.notifier).clearKey();
                Navigator.pop(ctx);
              },
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () {
              ref.read(cartoApiKeyProvider.notifier).setKey(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
    final dropboxAuth = ref.watch(dropboxAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Data Management', uppercase: true),
          Card(
            child: Column(
              children: [
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
                  subtitle: const Text('Export flights as CSV or JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reload Aircraft Types'),
                  subtitle: const Text('Fetch latest aircraft types from ICAO'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _reloadAircraftTypes,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Backup', uppercase: true),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('DropBox'),
                  trailing: dropboxAuth.when(
                    data: (isLoggedIn) => isLoggedIn
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, color: Colors.green),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(dropboxAuthProvider.notifier)
                                      .logout();
                                },
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: () async {
                              await ref
                                  .read(dropboxAuthProvider.notifier)
                                  .login();
                            },
                            child: const Text("Login"),
                          ),
                    error: (_, _) =>
                        const Icon(Icons.cancel, color: Colors.red),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
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

Future<void> _shareFile(String filePath, {required String text}) async {
  final uri = Uri(path: filePath, scheme: 'file');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
