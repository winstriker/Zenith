import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/person_providers.dart';
import '../repositories/person_repository.dart';
import '../services/database.dart';
import '../widgets/crew_card.dart';
import '../widgets/flight_card.dart';
import '../widgets/person_avatar.dart';
import 'flight_detail_page.dart';
import 'person_form_page.dart';
import 'person_select_page.dart';

/// Profile of a person: picture, stats and the flights flown together.
/// Edit, merge and delete live in the FABs.
class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId, this.initial});
  final int personId;

  /// The person as the caller already has them, shown until the stream
  /// delivers. Rendering the full page on the first frame lets the FAB hero
  /// morph from the previous page instead of hitting a loading spinner.
  final PersonWithLastFlight? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personProvider(personId));
    final initial = this.initial;
    if (initial != null && !personAsync.hasValue && !personAsync.hasError) {
      return _PersonDetailView(entry: initial);
    }

    return personAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (entry) {
        // Deleted or merged away: the page closes itself in the action.
        if (entry == null) return const Scaffold();
        return _PersonDetailView(entry: entry);
      },
    );
  }
}

class _PersonDetailView extends ConsumerWidget {
  const _PersonDetailView({required this.entry});
  final PersonWithLastFlight entry;

  Person get person => entry.person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flights = ref.watch(personFlightsProvider(person.id));
    final roles = ref.watch(personRolesProvider(person.id)).value ?? const {};

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
              heroTag: 'mergeFab',
              tooltip: 'Merge into another person',
              onPressed: () => _merge(context, ref),
              child: const Icon(Icons.merge_type),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.small(
              heroTag: 'deleteFab',
              tooltip: 'Delete',
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
                AppPageRoute<Person>(
                  builder: (_) => PersonFormPage(person: person),
                ),
              ),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(entry: entry)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Flights together',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            flights.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (flights) {
                if (flights.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flight_land,
                            size: 48,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No flights with ${person.name} yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: flights.length,
                  itemBuilder: (context, i) {
                    final flight = flights[i];
                    final role = roles[flight.flight.id];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                            child: Row(
                              children: [
                                CrewRoleBadge(role: role, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  role.displayName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        FlightCard(
                          flight: flight,
                          onTap: () => Navigator.push(
                            context,
                            AppPageRoute<void>(
                              builder: (_) =>
                                  FlightDetailPage(flightId: flight.flight.id),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 200)),
          ],
        ),
      ),
    );
  }

  Future<void> _merge(BuildContext context, WidgetRef ref) async {
    final target = await Navigator.push<Person>(
      context,
      AppPageRoute(
        builder: (_) => PersonSelectPage(
          title: 'Merge ${person.fullName} into…',
          excludeIds: {person.id},
          allowCreate: false,
        ),
      ),
    );
    if (target == null || !context.mounted) return;

    final confirmed = await _confirm(
      context,
      title: 'Merge People',
      message:
          'All flights of "${person.fullName}" will move to '
          '"${target.fullName}", and "${person.fullName}" will be deleted.',
      action: 'Merge',
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(personRepositoryProvider)
        .mergePeople(sourceId: person.id, targetId: target.id);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      AppPageRoute<void>(builder: (_) => PersonDetailPage(personId: target.id)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final n = entry.flightCount;
    final confirmed = await _confirm(
      context,
      title: 'Delete Person',
      message: n == 0
          ? 'Delete "${person.fullName}"?'
          : 'Delete "${person.fullName}"? They will be removed from the '
                'crew of ${n == 1 ? '1 flight' : '$n flights'}.',
      action: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(personRepositoryProvider).deletePerson(person.id);
    navigator.pop();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
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
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  )
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.entry});
  final PersonWithLastFlight entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final person = entry.person;
    final last = entry.lastFlight;

    return Container(
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
          GestureDetector(
            onTap: person.photo == null
                ? null
                : () => showPersonPhoto(
                    context,
                    person.photo!,
                    title: person.fullName,
                  ),
            child: PersonAvatar(
              name: person.name,
              photo: person.photo,
              radius: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            person.fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Flights together',
                  value: '${entry.flightCount}',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Last flight',
                  value: last == null ? '—' : DateFormat.yMMMd().format(last),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
