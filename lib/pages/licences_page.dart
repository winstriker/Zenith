import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../models/currency.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/licence_providers.dart';
import '../services/database.dart';
import '../widgets/currency_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import '../widgets/speed_dial_fab.dart';
import 'currency_settings_page.dart';
import 'licence_detail_page.dart';
import 'licence_form_page.dart';
import 'medical_detail_page.dart';
import 'medical_form_page.dart';
import 'rating_detail_page.dart';

/// Top-level tab: the pilot's licences, ratings and medicals, and whether
/// they are current.
class LicencesPage extends ConsumerWidget {
  const LicencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licences = ref.watch(licencesStreamProvider);
    final medicals = ref.watch(medicalsStreamProvider);
    final items = ref.watch(currencyItemsProvider);

    return Scaffold(
      floatingActionButton: const _LicencesFabs(),
      body: CustomScrollView(
        slivers: [
          PageHeader(
            'Licences',
            trailing: IconButton(
              tooltip: 'Reminders',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(
                context,
                AppPageRoute<void>(
                  builder: (_) => const CurrencySettingsPage(),
                ),
              ),
            ),
          ),
          switch ((licences, medicals, items)) {
            (AsyncError(:final error), _, _) ||
            (_, AsyncError(:final error), _) ||
            (_, _, AsyncError(:final error)) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $error')),
            ),
            (AsyncData(value: final l), AsyncData(value: final m), _)
                when l.isEmpty && m.isEmpty =>
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No licences yet',
                  subtitle:
                      'Add your licences, ratings and medical to see when '
                      'they expire and whether you are current.',
                ),
              ),
            (
              AsyncData(value: final l),
              AsyncData(value: final m),
              AsyncData(value: final i),
            ) =>
              _LicencesList(licences: l, medicals: m, items: i),
            _ => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _LicencesFabs extends StatelessWidget {
  const _LicencesFabs();

  @override
  Widget build(BuildContext context) {
    return SpeedDialFab(
      actions: [
        SpeedDialAction(
          heroTag: 'addMedicalFab',
          icon: Icons.medical_services_outlined,
          label: 'Add medical',
          onPressed: () => Navigator.push(
            context,
            AppPageRoute<void>(builder: (_) => const MedicalFormPage()),
          ),
        ),
      ],
      primaryIcon: Icons.add,
      primaryLabel: 'Add licence',
      onPrimaryPressed: () => Navigator.push(
        context,
        AppPageRoute<void>(builder: (_) => const LicenceFormPage()),
      ),
    );
  }
}

class _LicencesList extends ConsumerWidget {
  const _LicencesList({
    required this.licences,
    required this.medicals,
    required this.items,
  });

  final List<LicenceWithRatings> licences;
  final List<MedicalCertificate> medicals;
  final List<CurrencyItem> items;

  /// Opens the page [item] is about: its rating, its medical or its
  /// licence. The details sheet when there is none.
  void _open(BuildContext context, CurrencyItem item) {
    final medical = medicals.where((m) => m.id == item.medicalId).firstOrNull;
    final Widget? page = switch (item) {
      _ when medical != null => MedicalDetailPage(medicalId: medical.id),
      CurrencyItem(:final licenceId?, :final ratingId?) => RatingDetailPage(
        licenceId: licenceId,
        ratingId: ratingId,
      ),
      CurrencyItem(:final licenceId?) => LicenceDetailPage(
        licenceId: licenceId,
      ),
      _ => null,
    };
    if (page == null) {
      showCurrencyItemSheet(context, item);
      return;
    }
    Navigator.push(context, AppPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnDays = ref.watch(currencySettingsProvider).warnDays;
    final today = dateOnly(DateTime.now());
    // Expired or expiring dates, and recency about to lapse. Recency that
    // isn't met just means "not current": the Currency section shows it,
    // without crowding the headline.
    final attention = [
      for (final item in items)
        if (switch (item.statusOn(today, warnDays: warnDays)) {
          CurrencyStatus.valid => false,
          CurrencyStatus.expiring => true,
          CurrencyStatus.expired => item.kind == CurrencyKind.validity,
        })
          item,
    ];
    final recency = [
      for (final item in items)
        if (item.kind == CurrencyKind.recency) item,
    ];
    // Expiring recency is already in the summary, so the Currency section
    // only earns its place once something has actually lapsed.
    final anyRecencyExpired = recency.any(
      (item) =>
          item.statusOn(today, warnDays: warnDays) == CurrencyStatus.expired,
    );
    final byMedical = {
      for (final item in items)
        if (item.medicalId != null) item.medicalId!: item,
    };

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        // Clear of the FAB column and the nav bar.
        136 + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.list(
        children: [
          _Summary(
            attention: attention,
            onOpen: (item) => _open(context, item),
          ),
          if (anyRecencyExpired) ...[
            const SectionHeader(title: 'Currency', uppercase: true),
            Card(
              child: Column(
                children: [
                  for (final (i, item) in recency.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    CurrencyItemTile(item: item),
                  ],
                ],
              ),
            ),
          ],
          if (licences.isNotEmpty) ...[
            for (final l in licences)
              _LicenceCard(
                licence: l,
                items: {
                  for (final item in items)
                    if (item.kind == CurrencyKind.validity &&
                        item.ratingId != null)
                      item.ratingId!: item,
                },
              ),
          ],
          if (medicals.isNotEmpty) ...[
            const SectionHeader(title: 'Medical', uppercase: true),
            Card(
              child: Column(
                children: [
                  for (final (i, m) in medicals.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    CurrencyItemTile(
                      item: byMedical[m.id]!,
                      icon: Icons.medical_services_outlined,
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute<void>(
                          builder: (_) => MedicalDetailPage(medicalId: m.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What is expired or expiring soon, at the top of the page.
class _Summary extends ConsumerWidget {
  const _Summary({required this.attention, required this.onOpen});
  final List<CurrencyItem> attention;

  /// Opens the page of an item.
  final ValueChanged<CurrencyItem> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only shown when something needs attention.
    if (attention.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final warnDays = ref.watch(currencySettingsProvider).warnDays;
    final today = dateOnly(DateTime.now());
    final expired = attention
        .where(
          (i) =>
              i.statusOn(today, warnDays: warnDays) == CurrencyStatus.expired,
        )
        .length;
    final status = expired > 0
        ? CurrencyStatus.expired
        : CurrencyStatus.expiring;
    final style = currencyStatusStyle(context, status);
    final headline = [
      if (expired > 0) '$expired expired',
      if (attention.length - expired > 0)
        '${attention.length - expired} expiring soon',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(style.icon, color: style.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    headline,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: style.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            for (final item in attention)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpen(item),
                child: Padding(
                  padding: const EdgeInsets.only(left: 36, top: 6, bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyStatusText(item, today, warnDays),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: currencyStatusStyle(
                            context,
                            item.statusOn(today, warnDays: warnDays),
                          ).color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A licence with its ratings and their status.
class _LicenceCard extends StatelessWidget {
  const _LicenceCard({required this.licence, required this.items});

  final LicenceWithRatings licence;

  /// Validity items by rating id.
  final Map<int, CurrencyItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = licence.licence;
    final details = [l.issuedBy, l.number].nonNulls.where((s) => s.isNotEmpty);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          AppPageRoute<void>(
            builder: (_) => LicenceDetailPage(licenceId: l.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.badge),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (details.isNotEmpty)
                          Text(
                            details.join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (licence.ratings.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    'No ratings yet: tap to add them.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
              for (final r in licence.ratings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        ratingKindIcon(r.kind),
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r.title,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (items[r.id] case final item?)
                        CurrencyStatusPill(item: item)
                      else
                        Text(
                          'No expiry',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
