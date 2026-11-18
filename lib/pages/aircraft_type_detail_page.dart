import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../core/spacing.dart';
import '../providers/aircraft_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/base_card.dart';
import '../widgets/info_chip.dart';
import '../widgets/info_row.dart';
import 'aircraft_detail_page.dart';
import 'aircraft_type_form_page.dart';

/// Everything known about an aircraft type, and the user's aircraft of it.
/// Custom types can be edited and deleted from the FABs.
class AircraftTypeDetailPage extends ConsumerWidget {
  const AircraftTypeDetailPage({super.key, required this.initial});

  /// The type as the caller has it, shown until (and after a delete, instead
  /// of) the live one.
  final IcaoAircraft initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final type = ref.watch(icaoAircraftProvider(initial.id)).value ?? initial;
    final aircraft = ref.watch(aircraftsOfTypeProvider(type.id));

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: !type.userInserted
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'deleteFab',
                    tooltip: 'Delete',
                    backgroundColor: cs.errorContainer,
                    foregroundColor: cs.onErrorContainer,
                    onPressed: () => _delete(context, ref, type),
                    child: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: primaryFabHeroTag,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () => Navigator.push(
                      context,
                      AppPageRoute<IcaoAircraft>(
                        builder: (_) => AircraftTypeFormPage(type: type),
                      ),
                    ),
                  ),
                ],
              ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 72,
                  16,
                  24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondaryContainer,
                      cs.secondaryContainer.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      type.designator,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${type.manufacturer} ${type.modelFullName}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (type.userInserted) ...[
                      const SizedBox(height: 8),
                      InfoChip(
                        label: 'Custom type',
                        backgroundColor: cs.tertiaryContainer,
                        textColor: cs.onTertiaryContainer,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: BaseCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'Designator', value: type.designator),
                      InfoRow(label: 'Manufacturer', value: type.manufacturer),
                      InfoRow(label: 'Model', value: type.modelFullName),
                      InfoRow(
                        label: 'Description',
                        value: type.description.name,
                      ),
                      InfoRow(
                        label: 'Engines',
                        value: '${type.engineCount}x ${type.engineType.name}',
                      ),
                      InfoRow(
                        label: 'Wake',
                        value:
                            'Category ${type.wakeTurbolenceCategory.name}, '
                            'group ${type.wakeTurbolenceGroup.name}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Aircraft',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            aircraft.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (aircraft) => aircraft.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: Text(
                          'No aircraft of this type yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : SliverList.builder(
                      itemCount: aircraft.length,
                      itemBuilder: (context, i) => AircraftCard(
                        aircraft: aircraft[i],
                        showStats: true,
                        onTap: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                            builder: (_) =>
                                AircraftDetailPage(aircraftId: aircraft[i].id),
                          ),
                        ),
                      ),
                    ),
            ),
            // Clear of the FABs.
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    IcaoAircraft type,
  ) async {
    final repo = ref.read(aircraftRepositoryProvider);
    final used = await repo.countTypeUsage(type.id);
    if (!context.mounted) return;
    if (used > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Type in use'),
          content: Text(
            '${type.designator} is used by '
            '${used == 1 ? '1 aircraft or simulator' : '$used aircraft and simulators'}. '
            'Change their type before deleting it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft Type'),
        content: Text('Delete "${type.designator} ${type.modelFullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    // False when an aircraft took the type in the meantime: stay.
    if (await repo.deleteIcaoAircraft(type.id)) navigator.pop();
  }
}
