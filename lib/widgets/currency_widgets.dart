import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/currency.dart';
import '../providers/currency_settings_provider.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import 'info_chip.dart';

final _dateFormat = DateFormat('d MMM yyyy');

/// "12 Mar 2027".
String formatLicenceDate(DateTime date) => _dateFormat.format(date);

/// Icon for a rating kind.
IconData ratingKindIcon(RatingKind kind) => switch (kind) {
  RatingKind.classRating => Icons.flight,
  RatingKind.typeRating => Icons.airplanemode_active,
  RatingKind.instrument ||
  RatingKind.enRouteInstrument ||
  RatingKind.basicInstrument => Icons.explore_outlined,
  RatingKind.night => Icons.nightlight_outlined,
  RatingKind.mountain => Icons.terrain_outlined,
  RatingKind.instructor || RatingKind.examiner => Icons.school_outlined,
  RatingKind.languageProficiency => Icons.translate,
  RatingKind.aerobatic ||
  RatingKind.towing ||
  RatingKind.flightTest ||
  RatingKind.other => Icons.workspace_premium_outlined,
};

/// Colour and icon of a [CurrencyStatus].
({Color color, IconData icon}) currencyStatusStyle(
  BuildContext context,
  CurrencyStatus status,
) {
  final colors = context.appColors;
  return switch (status) {
    CurrencyStatus.valid => (
      color: colors.success,
      icon: Icons.check_circle_outline,
    ),
    CurrencyStatus.expiring => (color: colors.warning, icon: Icons.schedule),
    CurrencyStatus.expired => (
      color: Theme.of(context).colorScheme.error,
      icon: Icons.error_outline,
    ),
  };
}

/// "Valid until 12 Mar 2027", "Expires in 12 days", "Expired 3 days ago".
String currencyStatusText(CurrencyItem item, DateTime today, int warnDays) {
  final left = item.daysLeft(today);
  final recency = item.kind == CurrencyKind.recency;
  if (left == null) return 'Not current';
  if (left < 0) {
    final ago = -left;
    final word = recency ? 'Lapsed' : 'Expired';
    return ago == 1 ? '$word yesterday' : '$word $ago days ago';
  }
  final until = formatLicenceDate(item.validUntil!);
  if (left > warnDays) {
    return recency ? 'Current until $until' : 'Valid until $until';
  }
  final verb = recency ? 'Lapses' : 'Expires';
  return switch (left) {
    0 => '$verb today',
    1 => '$verb tomorrow',
    _ => '$verb in $left days',
  };
}

/// The status of [item] as a chip, like the aircraft class chips.
class CurrencyStatusPill extends ConsumerWidget {
  const CurrencyStatusPill({super.key, required this.item});
  final CurrencyItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnDays = ref.watch(currencySettingsProvider).warnDays;
    final today = dateOnly(DateTime.now());
    final status = item.statusOn(today, warnDays: warnDays);
    final style = currencyStatusStyle(context, status);
    final cs = Theme.of(context).colorScheme;
    final (background, foreground) = (
      Color.alphaBlend(style.color.withValues(alpha: 0.22), cs.surface),
      style.color,
    );
    return InfoChip(
      icon: style.icon,
      label: currencyStatusText(item, today, warnDays),
      backgroundColor: background,
      textColor: foreground,
    );
  }
}

class RequirementRow extends StatelessWidget {
  const RequirementRow({super.key, required this.requirement});
  final Requirement requirement;

  String _format(int value) => switch (requirement.unit) {
    RequirementUnit.count => '$value',
    RequirementUnit.minutes => DurationFormatter.hm(Duration(minutes: value)),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final met = requirement.met;
    final color = met ? context.appColors.success : cs.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: met ? color : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requirement.label,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${_format(requirement.done)} / ${_format(requirement.needed)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: met ? color : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: requirement.progress,
              minHeight: 6,
              color: color,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Requirements, notes and rule of [item], then its other sections: the
/// body of its details.
class CurrencyItemDetails extends StatelessWidget {
  const CurrencyItemDetails({
    super.key,
    required this.item,
    this.notesInPopup = false,
  });
  final CurrencyItem item;

  /// Whether the notes and the rule go behind an info button on each
  /// section's title, instead of under its requirements.
  final bool notesInPopup;

  @override
  Widget build(BuildContext context) {
    final hasRequirements = item.requirements.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasRequirements)
          _RequirementsBlock(
            title: item.requirementsTitle ?? 'Requirements',
            requirements: item.requirements,
            anyRequirement: item.anyRequirement,
            met: item.requirementsMet,
            info: notesInPopup && item.hasInfo
                ? CurrencyInfoButton(
                    title: item.title,
                    notes: item.notes,
                    reference: item.reference,
                  )
                : null,
          ),
        if (!notesInPopup)
          ...currencyNotes(context, item.notes, item.reference),
        for (final (i, section) in item.sections.indexed) ...[
          if (hasRequirements || i > 0) const SizedBox(height: 16),
          _RequirementsBlock(
            title: section.title,
            requirements: section.requirements,
            met: section.met,
            info:
                notesInPopup &&
                    (section.notes.isNotEmpty || section.reference != null)
                ? CurrencyInfoButton(
                    title: section.title,
                    notes: section.notes,
                    reference: section.reference,
                  )
                : null,
          ),
          if (!notesInPopup)
            ...currencyNotes(context, section.notes, section.reference),
        ],
      ],
    );
  }
}

/// A title, with "Met" and [info] on its right, and [requirements] under it.
class _RequirementsBlock extends StatelessWidget {
  const _RequirementsBlock({
    required this.title,
    required this.requirements,
    required this.met,
    this.anyRequirement = false,
    this.info,
  });

  final String title;
  final List<Requirement> requirements;
  final bool met;
  final bool anyRequirement;
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (met)
              Text(
                'Met',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.appColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ?info,
          ],
        ),
        if (anyRequirement)
          Text(
            'One of these is enough',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 4),
        for (final r in requirements) RequirementRow(requirement: r),
      ],
    );
  }
}

/// [notes] and the rule ([reference]), one line each.
List<Widget> currencyNotes(
  BuildContext context,
  List<String> notes,
  String? reference,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return [
    for (final note in notes)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    if (reference != null)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'EASA Part-$reference',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
  ];
}

extension CurrencyItemInfo on CurrencyItem {
  /// Whether there are notes or a rule to show.
  bool get hasInfo => notes.isNotEmpty || reference != null;
}

/// Small info button showing [notes] and the rule ([reference]) in a dialog
/// titled [title].
class CurrencyInfoButton extends StatelessWidget {
  const CurrencyInfoButton({
    super.key,
    required this.title,
    required this.notes,
    this.reference,
  });

  CurrencyInfoButton.of(CurrencyItem item, {Key? key})
    : this(
        key: key,
        title: item.title,
        notes: item.notes,
        reference: item.reference,
      );

  final String title;
  final List<String> notes;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More info',
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      icon: const Icon(Icons.info_outline),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: currencyNotes(context, notes, reference),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card with [item]'s title, status and requirements; its notes and rule
/// are behind an info button.
class CurrencyItemCard extends StatelessWidget {
  const CurrencyItemCard({
    super.key,
    required this.item,
    required this.icon,
    this.title,
  });
  final CurrencyItem item;
  final IconData icon;

  /// Shown instead of the item's title, e.g. when the page already names it.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRequirements = item.requirements.isNotEmpty;
    final hasDetails = hasRequirements || item.sections.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title ?? item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(child: CurrencyStatusPill(item: item)),
                // Without requirements there is no title line for the info
                // button: it goes next to the status.
                if (!hasRequirements && item.hasInfo)
                  CurrencyInfoButton.of(item),
              ],
            ),
            if (hasDetails) ...[
              const SizedBox(height: 12),
              CurrencyItemDetails(item: item, notesInPopup: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row for [item]: status icon, title, subtitle and status pill. Tapping
/// it shows its details, unless [onTap] says otherwise.
class CurrencyItemTile extends ConsumerWidget {
  const CurrencyItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.icon,
  });

  final CurrencyItem item;
  final VoidCallback? onTap;

  /// Shown instead of the status icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final warnDays = ref.watch(currencySettingsProvider).warnDays;
    final status = item.statusOn(dateOnly(DateTime.now()), warnDays: warnDays);
    final style = currencyStatusStyle(context, status);
    final subtitle = item.subtitle;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: style.color.withValues(alpha: 0.14),
        foregroundColor: style.color,
        child: Icon(icon ?? style.icon),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null && subtitle.isNotEmpty)
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          CurrencyStatusPill(item: item),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap ?? () => showCurrencyItemSheet(context, item),
    );
  }
}

/// Bottom sheet with everything about [item].
Future<void> showCurrencyItemSheet(BuildContext context, CurrencyItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.subtitle case final s? when s.isNotEmpty)
                  Text(
                    s,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CurrencyStatusPill(item: item),
                ),
                const SizedBox(height: 16),
                CurrencyItemDetails(item: item),
              ],
            ),
          ),
        ),
      );
    },
  );
}
