import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../models/currency.dart';
import '../providers/licence_providers.dart';
import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/currency_widgets.dart';
import '../widgets/info_row.dart';
import '../widgets/licence_form_widgets.dart';
import '../widgets/page_title.dart';
import 'licence_form_page.dart';
import 'rating_detail_page.dart';
import 'rating_form_page.dart';

/// A licence: its details, its ratings with their validity and revalidation
/// progress, and its recency.
class LicenceDetailPage extends ConsumerWidget {
  const LicenceDetailPage({super.key, required this.licenceId});
  final int licenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(licenceByIdStreamProvider(licenceId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          // Deleted: the page closes itself in the action.
          data: (licence) => licence == null
              ? const Scaffold()
              : _LicenceDetailView(licence: licence),
        );
  }
}

class _LicenceDetailView extends ConsumerWidget {
  const _LicenceDetailView({required this.licence});
  final LicenceWithRatings licence;

  Licence get l => licence.licence;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmLicenceDelete(
      context,
      title: 'Delete ${l.title}',
      message: 'The licence and all its ratings will be deleted.',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.pop(context);
    await ref.read(licenceRepositoryProvider).deleteLicence(l.id);
  }

  void _addRating(BuildContext context) => Navigator.push(
    context,
    AppPageRoute<void>(builder: (_) => RatingFormPage(licence: l)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = ref.watch(currencyItemsProvider).value ?? const [];
    final validity = {
      for (final item in items)
        // A mountain rating doesn't expire: its card shows whether its
        // privileges can be used (FCL.815(d)).
        if ((item.kind == CurrencyKind.validity ||
                item.key.startsWith('mountain:')) &&
            item.ratingId != null)
          item.ratingId!: item,
    };
    final recency = [
      for (final item in items)
        if (item.kind == CurrencyKind.recency &&
            item.licenceId == l.id &&
            (item.key.startsWith('lapl:') || item.key.startsWith('gpl')))
          item,
    ];

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'deleteFab',
              tooltip: 'Delete licence',
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              onPressed: () => _delete(context, ref),
              child: const Icon(Icons.delete_outline),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.small(
              heroTag: 'editLicenceFab',
              tooltip: 'Edit licence',
              onPressed: () => Navigator.push(
                context,
                AppPageRoute<void>(builder: (_) => LicenceFormPage(licence: l)),
              ),
              child: const Icon(Icons.edit),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: primaryFabHeroTag,
              icon: const Icon(Icons.add),
              label: const Text('Add rating'),
              onPressed: () => _addRating(context),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PageTitle(l.title, belowCloseButton: true, bottomPadding: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.kind.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(licence: l),
                  for (final item in recency) ...[
                    const SizedBox(height: 16),
                    CurrencyItemCard(item: item, icon: Icons.update),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ratings & certificates',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addRating(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  if (licence.ratings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Add the class and type ratings, IR, instructor '
                        'certificates and language proficiency written on '
                        'this licence.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final r in licence.ratings) ...[
                    _RatingCard(licence: l, rating: r, item: validity[r.id]),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.licence});
  final Licence licence;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (licence.number case final n? when n.isNotEmpty)
        InfoRow(label: 'Number', value: n),
      if (licence.issuedBy case final a? when a.isNotEmpty)
        InfoRow(label: 'Issued by', value: a),
      if (licence.issueDate case final d?)
        InfoRow(label: 'Issued on', value: formatLicenceDate(d)),
      if (licence.proficiencyCheckDate case final d?)
        InfoRow(label: 'Proficiency check', value: formatLicenceDate(d)),
      if (licence.notes case final n? when n.isNotEmpty)
        InfoRow(label: 'Notes', value: n),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: row,
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.licence,
    required this.rating,
    required this.item,
  });

  final Licence licence;
  final LicenceRating rating;

  /// Validity of the rating, when it expires.
  final CurrencyItem? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = this.item;
    final subtitle = [
      if (rating.kind != RatingKind.instrument &&
          rating.kind != RatingKind.basicInstrument &&
          rating.kind != RatingKind.classRating &&
          rating.kind != RatingKind.night &&
          rating.kind != RatingKind.mountain)
        rating.kind.label,
      if (rating.kind == RatingKind.classRating)
        rating.aircraftClass?.description,
      if (rating.lastCheckDate case final d?)
        'Last check ${formatLicenceDate(d)}',
    ].nonNulls.join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          AppPageRoute<void>(
            builder: (_) =>
                RatingDetailPage(licenceId: licence.id, ratingId: rating.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                    child: Icon(ratingKindIcon(rating.kind)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: item == null
                    ? Text(
                        'No expiry',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : CurrencyStatusPill(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
