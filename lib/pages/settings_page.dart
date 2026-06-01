import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flight_providers.dart';
import '../services/flight_service.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _useMetric = true;

  void _clearAllFlights() {
    showDialog(
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
              final sessions = FlightService().sessions.toList();
              for (final s in sessions) {
                await FlightService().deleteSession(s.sessionId);
              }
              ref.read(flightListProvider.notifier).refresh();
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

  void _exportData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Export coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const _SectionHeader(title: 'Preferences'),
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
                SwitchListTile(
                  secondary: Icon(
                    _useMetric ? Icons.straighten : Icons.monitor_weight,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Metric Units'),
                  subtitle: Text(_useMetric ? 'km, m, km/h' : 'nm, ft, kts'),
                  value: _useMetric,
                  onChanged: (v) => setState(() => _useMetric = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Data Management'),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flight_takeoff),
                  title: const Text('Logbook'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Description'),
                  subtitle: const Text('Pilot Flight Tracker'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Logbook v1.0.0',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
