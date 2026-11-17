import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/licence_providers.dart';
import 'currency_widgets.dart';
import 'page_title.dart';

/// A form field holding a date that may be left empty.
class OptionalDateField extends StatelessWidget {
  const OptionalDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.event_outlined,
    this.helperText,
    this.errorText,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final IconData icon;
  final String? helperText;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(now.year + 20),
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          helperMaxLines: 3,
          errorText: errorText,
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: value == null
            ? null
            : Text(formatLicenceDate(value!), style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

/// Layout of the licence, rating and medical forms: close button top left,
/// the page title, the fields, and the save button.
class LicenceFormScaffold extends StatelessWidget {
  const LicenceFormScaffold({
    super.key,
    required this.title,
    required this.isEditing,
    required this.saving,
    required this.onSave,
    required this.children,
    this.subtitle,
    this.onDelete,
  });

  final String title;

  /// Shown under the title, in grey.
  final String? subtitle;
  final bool isEditing;
  final bool saving;
  final VoidCallback onSave;

  /// Shown as a small FAB above the save one, when editing.
  final VoidCallback? onDelete;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        heroTag: closeFabHeroTag,
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onDelete != null) ...[
              FloatingActionButton.small(
                heroTag: 'deleteFab',
                tooltip: 'Delete',
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.onErrorContainer,
                onPressed: saving ? null : onDelete,
                child: const Icon(Icons.delete_outline),
              ),
              const SizedBox(height: 12),
            ],
            FloatingActionButton.extended(
              onPressed: saving ? null : onSave,
              heroTag: primaryFabHeroTag,
              label: Text(isEditing ? 'Save' : 'Add'),
              icon: Icon(isEditing ? Icons.save : Icons.add),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PageTitle(title, belowCloseButton: true, bottomPadding: 0),
            if (subtitle case final subtitle?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              // Bottom padding keeps the last field clear of the FABs.
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the notification permission when reminders are on, so they can
/// be shown. Android only asks once; later calls return at once.
Future<void> askForReminderPermission(WidgetRef ref) async {
  if (!ref.read(currencySettingsProvider).notificationsEnabled) return;
  await ref.read(currencyReminderServiceProvider).requestPermission();
}

/// Asks to confirm deleting something. True when confirmed.
Future<bool> confirmLicenceDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
