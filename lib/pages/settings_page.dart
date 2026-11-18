import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../providers/aircraft_providers.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/flight_providers.dart';
import '../repositories/flight_repository.dart';
import '../widgets/page_header.dart';
import 'adsb_settings_page.dart';
import 'backup_settings_page.dart';
import 'currency_settings_page.dart';
import 'export_page.dart';
import 'map_settings_page.dart';
import 'people_page.dart';
import 'personal_data_page.dart';
import 'photo_settings_page.dart';
import 'theme_settings_page.dart';
import 'updates_page.dart';

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
              final sessions = await ref
                  .read(flightRepositoryProvider)
                  .allRecordedFlights();
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

  Widget _tile(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
    Color? iconColor,
  ) => Padding(
    padding: const EdgeInsetsGeometry.fromLTRB(0, 6, 0, 6),
    child: ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  void _open(Widget page) =>
      Navigator.push(context, AppPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySettings = ref.watch(currencySettingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const PageHeader('Settings'),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              8 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, tile) in <Widget>[
                        _tile(
                          Icons.account_circle_outlined,
                          'Personal Data',
                          null,
                          () => _open(const PersonalDataPage()),
                          null,
                        ),
                        _tile(
                          Icons.palette_outlined,
                          'Theme',
                          null,
                          () => _open(const ThemeSettingsPage()),
                          null,
                        ),
                        _tile(
                          Icons.file_download_outlined,
                          'Export Data',
                          null,
                          () => _open(const ExportPage()),
                          null,
                        ),
                        _tile(
                          Icons.radar,
                          'ADS-B Providers',
                          null,
                          () => _open(const AdsbSettingsPage()),
                          null,
                        ),
                        _tile(
                          Icons.photo_library_outlined,
                          'Photo Providers',
                          null,
                          () => _open(const PhotoSettingsPage()),
                          null,
                        ),
                        _tile(
                          Icons.map_outlined,
                          'Map',
                          null,
                          () => _open(const MapSettingsPage()),
                          null,
                        ),
                        _tile(
                          Icons.people_outline,
                          'People',
                          null,
                          () => _open(const PeoplePage()),
                          null,
                        ),
                        _tile(
                          Icons.backup_outlined,
                          'Backup Settings',
                          null,
                          () => _open(const BackupSettingsPage()),
                          null,
                        ),
                        _tile(
                          currencySettings.notificationsEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          'Expiry Reminders',
                          null,
                          () => _open(const CurrencySettingsPage()),
                          null,
                        ),
                        _tile(
                          Icons.update,
                          'Updates',
                          null,
                          () => _open(const UpdatesPage()),
                          null,
                        ),
                        _tile(
                          Icons.refresh,
                          'Reload Aircraft Types',
                          null,
                          _reloadAircraftTypes,
                          null,
                        ),
                        _tile(
                          Icons.delete_forever,
                          'Delete All Flights',
                          null,
                          _clearAllFlights,
                          theme.colorScheme.error,
                        ),
                      ].indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 16),
                        tile,
                      ],
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
          ),
        ],
      ),
    );
  }
}
