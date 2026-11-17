import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../providers/aircraft_providers.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/map_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/unit_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';
import 'adsb_settings_page.dart';
import 'backup_settings_page.dart';
import 'currency_settings_page.dart';
import 'export_page.dart';
import 'map_settings_page.dart';
import 'people_page.dart';
import 'photo_settings_page.dart';

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
    final mapSource = ref.watch(effectiveMapSourceProvider);
    final picNameMode = ref.watch(picNameModeProvider);
    final currencySettings = ref.watch(currencySettingsProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle('Settings', horizontalPadding: 0),
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
                ListTile(
                  leading: Icon(Icons.map, color: theme.colorScheme.primary),
                  title: Text('Map', style: theme.textTheme.titleMedium),
                  subtitle: Text(switch (mapSource) {
                    MapSource.carto => 'CARTO Voyager',
                    MapSource.osm => 'OpenStreetMap',
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute<void>(builder: (_) => const MapSettingsPage()),
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
          const SectionHeader(title: 'Licences & Currency', uppercase: true),
          Card(
            child: ListTile(
              leading: Icon(
                currencySettings.notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: const Text('Expiry Reminders'),
              subtitle: Text(
                !currencySettings.notificationsEnabled
                    ? 'Off'
                    : currencySettings.leads.isEmpty
                    ? 'No reminders selected'
                    : [
                        for (final lead in ReminderLead.values)
                          if (currencySettings.leads.contains(lead)) lead.label,
                      ].join(', '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                AppPageRoute<void>(
                  builder: (_) => const CurrencySettingsPage(),
                ),
              ),
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
                    AppPageRoute<void>(builder: (_) => const PeoplePage()),
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
                    AppPageRoute<void>(builder: (_) => const ExportPage()),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Online Data', uppercase: true),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.radar),
                  title: const Text('ADS-B Providers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute<void>(
                      builder: (_) => const AdsbSettingsPage(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Photo Providers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute<void>(
                      builder: (_) => const PhotoSettingsPage(),
                    ),
                  ),
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
                AppPageRoute<void>(builder: (_) => const BackupSettingsPage()),
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
