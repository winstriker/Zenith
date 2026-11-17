import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/licence_providers.dart';
import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/currency_widgets.dart';
import '../widgets/info_row.dart';
import '../widgets/licence_form_widgets.dart';
import '../widgets/page_title.dart';
import 'medical_form_page.dart';

/// A medical certificate: its details and its validity.
class MedicalDetailPage extends ConsumerWidget {
  const MedicalDetailPage({super.key, required this.medicalId});
  final int medicalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(medicalByIdStreamProvider(medicalId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          // Deleted: the page closes itself in the action.
          data: (medical) => medical == null
              ? const Scaffold()
              : _MedicalDetailView(medical: medical),
        );
  }
}

class _MedicalDetailView extends ConsumerWidget {
  const _MedicalDetailView({required this.medical});
  final MedicalCertificate medical;

  String get _title => 'Medical ${medical.medicalClass.label}';

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmLicenceDelete(
      context,
      title: 'Delete medical',
      message:
          'The ${medical.medicalClass.label} medical certificate will be '
          'deleted.',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.pop(context);
    await ref.read(licenceRepositoryProvider).deleteMedical(medical.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final items = ref.watch(currencyItemsProvider).value ?? const [];
    final validity = items
        .where((i) => i.key == 'medical:${medical.id}')
        .firstOrNull;

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
              tooltip: 'Delete medical',
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
                AppPageRoute<void>(
                  builder: (_) => MedicalFormPage(medical: medical),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PageTitle(_title, belowCloseButton: true, bottomPadding: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(medical: medical),
                  if (validity != null) ...[
                    const SizedBox(height: 16),
                    CurrencyItemCard(
                      item: validity,
                      icon: Icons.event_available_outlined,
                      title: 'Validity',
                    ),
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
  const _InfoCard({required this.medical});
  final MedicalCertificate medical;

  @override
  Widget build(BuildContext context) {
    final rows = [
      InfoRow(label: 'Class', value: medical.medicalClass.label),
      if (medical.examinationDate case final d?)
        InfoRow(label: 'Examined on', value: formatLicenceDate(d)),
      InfoRow(
        label: 'Valid until',
        value: formatLicenceDate(medical.expiryDate),
      ),
      if (medical.limitations case final l? when l.isNotEmpty)
        InfoRow(label: 'Limitations', value: l),
      if (medical.notes case final n? when n.isNotEmpty)
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
