import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/licence_providers.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';

/// When to be reminded that a licence, rating, medical or recency is about
/// to expire.
class CurrencySettingsPage extends ConsumerStatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  ConsumerState<CurrencySettingsPage> createState() =>
      _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends ConsumerState<CurrencySettingsPage> {
  /// Whether Android lets the app post notifications; null until known.
  bool? _permitted;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    // The permission may be changed from the system settings meanwhile.
    _lifecycle = AppLifecycleListener(onResume: _checkPermission);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final permitted = await ref
        .read(currencyReminderServiceProvider)
        .areEnabled();
    if (mounted) setState(() => _permitted = permitted);
  }

  Future<void> _requestPermission() async {
    final granted = await ref
        .read(currencyReminderServiceProvider)
        .requestPermission();
    if (!mounted) return;
    setState(() => _permitted = granted);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are off for Zenith: turn them on in the system '
            'settings.',
          ),
        ),
      );
    }
  }

  Future<void> _setEnabled({required bool enabled}) async {
    await ref
        .read(currencySettingsProvider.notifier)
        .setNotificationsEnabled(enabled: enabled);
    if (enabled && _permitted == false) await _requestPermission();
  }

  Future<void> _pickTime(TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'Reminder time',
    );
    if (picked != null) {
      await ref.read(currencySettingsProvider.notifier).setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = ref.watch(currencySettingsProvider);
    final notifier = ref.read(currencySettingsProvider.notifier);
    final enabled = settings.notificationsEnabled;

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
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle(
            'Licence Reminders',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    enabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: cs.primary,
                  ),
                  title: const Text('Reminders'),
                  subtitle: const Text(
                    'Notify me before licences, ratings, medicals and '
                    'currency expire',
                  ),
                  value: enabled,
                  onChanged: (v) => _setEnabled(enabled: v),
                ),
                if (enabled && _permitted == false) ...[
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: Icon(Icons.warning_amber, color: cs.error),
                    title: const Text('Notifications are blocked'),
                    subtitle: const Text(
                      'Reminders can\'t be shown until Zenith may post '
                      'notifications.',
                    ),
                    trailing: TextButton(
                      onPressed: _requestPermission,
                      child: const Text('Allow'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Remind me', uppercase: true),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before the expiry date',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final lead in ReminderLead.values)
                        FilterChip(
                          label: Text(lead.label),
                          selected: settings.leads.contains(lead),
                          onSelected: enabled
                              ? (v) => notifier.setLead(lead, enabled: v)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    settings.leads.isEmpty
                        ? 'No reminders will be sent.'
                        : 'Items are shown as expiring from '
                              '${settings.warnDays} days before.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  enabled: enabled,
                  leading: Icon(Icons.access_time, color: cs.primary),
                  title: const Text('Time of day'),
                  subtitle: Text(settings.reminderTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTime(settings.reminderTime),
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  secondary: Icon(Icons.update, color: cs.primary),
                  title: const Text('Recency from the logbook'),
                  subtitle: const Text(
                    'Also remind me when passenger (90 days) or LAPL recency '
                    'is about to lapse',
                  ),
                  value: settings.recencyReminders,
                  onChanged: enabled
                      ? (v) => notifier.setRecencyReminders(enabled: v)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Recency is worked out from the flights in your logbook, using '
              'each aircraft\'s class or type rating. Validity follows EASA '
              'Part-FCL; always check the dates endorsed on your licence.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
