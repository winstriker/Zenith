import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../models/currency.dart';
import '../providers/licence_providers.dart';
import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/currency_widgets.dart';
import '../widgets/info_row.dart';
import '../widgets/licence_form_widgets.dart';
import '../widgets/page_title.dart';
import 'rating_form_page.dart';

/// A rating of a licence: its details, its validity and revalidation
/// progress, and the currency worked out for it from the logbook.
class RatingDetailPage extends ConsumerWidget {
  const RatingDetailPage({
    super.key,
    required this.licenceId,
    required this.ratingId,
  });

  final int licenceId;
  final int ratingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(licenceByIdStreamProvider(licenceId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (licence) {
            final rating = licence?.ratings
                .where((r) => r.id == ratingId)
                .firstOrNull;
            // Deleted: the page closes itself in the action.
            if (licence == null || rating == null) return const Scaffold();
            return _RatingDetailView(licence: licence.licence, rating: rating);
          },
        );
  }
}

class _RatingDetailView extends ConsumerWidget {
  const _RatingDetailView({required this.licence, required this.rating});

  final Licence licence;
  final LicenceRating rating;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmLicenceDelete(
      context,
      title: 'Delete ${rating.title}',
      message: 'The rating will be removed from ${licence.title}.',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.pop(context);
    await ref.read(licenceRepositoryProvider).deleteRating(rating.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = ref.watch(currencyItemsProvider).value ?? const [];
    final validity = items
        .where((i) => i.key == 'rating:${rating.id}')
        .firstOrNull;
    final recency = [
      for (final item in items)
        if (item.kind == CurrencyKind.recency && item.ratingId == rating.id)
          item,
    ];
    final description = switch (rating.kind) {
      RatingKind.classRating => rating.aircraftClass?.description,
      _ => rating.kind.label,
    };

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
              tooltip: 'Delete rating',
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              onPressed: () => _delete(context, ref),
              child: const Icon(Icons.delete_outline),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: primaryFabHeroTag,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RatingFormPage(licence: licence, rating: rating),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PageTitle(rating.title, belowCloseButton: true, bottomPadding: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                [?description, licence.title].join(' · '),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(rating: rating, lastCheck: validity?.lastCheck),
                  if (validity != null) ...[
                    const SizedBox(height: 16),
                    CurrencyItemCard(
                      item: validity,
                      icon: Icons.event_available_outlined,
                      title: 'Validity',
                    ),
                  ],
                  if (recency.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                      child: Text(
                        'Currency',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final (i, item) in recency.indexed) ...[
                      if (i > 0) const SizedBox(height: 12),
                      CurrencyItemCard(item: item, icon: Icons.update),
                    ],
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
  const _InfoCard({required this.rating, this.lastCheck});
  final LicenceRating rating;

  /// The last check worked out with the logbook's checks, when known.
  final DateTime? lastCheck;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (rating.level case final level?)
        InfoRow(label: 'Level', value: '$level'),
      if (rating.issueDate case final d?)
        InfoRow(label: 'Issued on', value: formatLicenceDate(d)),
      if (lastCheck ?? rating.lastCheckDate case final d?)
        InfoRow(label: 'Last check', value: formatLicenceDate(d)),
      InfoRow(
        label: 'Valid until',
        value: switch (rating.expiryDate) {
          final d? => formatLicenceDate(d),
          null => 'No expiry',
        },
      ),
      if (rating.notes case final n? when n.isNotEmpty)
        InfoRow(label: 'Notes', value: n),
    ];
    return Card(
      margin: EdgeInsets.zero,
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
