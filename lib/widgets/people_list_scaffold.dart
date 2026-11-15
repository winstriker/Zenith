import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/fab_hero_tags.dart';

import '../pages/person_form_page.dart';
import '../providers/person_providers.dart';
import '../services/database.dart';
import 'empty_state.dart';
import 'person_tile.dart';

/// Searchable list of people, most recently flown with first, framed like the
/// detail pages: a close FAB at the top-left and an "Add" FAB at the
/// bottom-right.
///
/// Shared by the people list and the person picker so the two stay identical
/// apart from what tapping a person does.
class PeopleListScaffold extends ConsumerStatefulWidget {
  const PeopleListScaffold({
    super.key,
    required this.title,
    required this.onTap,
    this.excludeIds,
    this.allowCreate = true,
    this.onCreated,
    this.autofocusSearch = false,
  });

  final String title;
  final void Function(PersonWithLastFlight entry) onTap;

  /// People hidden from the list (e.g. already on the crew).
  final Set<int>? excludeIds;

  /// Whether the "Add" FAB is shown.
  final bool allowCreate;

  /// Called with the person just created through the "Add" FAB.
  final void Function(Person person)? onCreated;

  final bool autofocusSearch;

  @override
  ConsumerState<PeopleListScaffold> createState() => _PeopleListScaffoldState();
}

class _PeopleListScaffoldState extends ConsumerState<PeopleListScaffold> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider(_query));
    final excluded = widget.excludeIds ?? const <int>{};
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: widget.allowCreate
            ? FloatingActionButton.extended(
                heroTag: primaryFabHeroTag,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add'),
                onPressed: _addPerson,
              )
            : null,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Leaves room for the close FAB pinned at the top-left.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 80,
                  16,
                  8,
                ),
                child: Text(
                  widget.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: widget.autofocusSearch,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            ),
            ...peopleAsync.when(
              data: (all) {
                final people = all
                    .where((p) => !excluded.contains(p.person.id))
                    .toList();
                if (people.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _query.isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outline,
                              title: 'No people yet',
                              subtitle:
                                  'People you add as crew on a flight appear here.',
                            )
                          : EmptyState(
                              icon: Icons.search_off,
                              iconSize: 48,
                              iconOpacity: 0.4,
                              title: 'No people match "$_query"',
                            ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    sliver: SliverList.separated(
                      itemCount: people.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) => PersonTile(
                        entry: people[i],
                        onTap: () => widget.onTap(people[i]),
                      ),
                    ),
                  ),
                ];
              },
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the person form, prefilled with whatever was typed in the search.
  Future<void> _addPerson() async {
    final words = _query.split(RegExp(r'\s+'));
    final person = await Navigator.push(
      context,
      MaterialPageRoute<Person>(
        builder: (_) => PersonFormPage(
          initialName: words.isNotEmpty ? words.first : '',
          initialSurname: words.length > 1 ? words.skip(1).join(' ') : '',
        ),
      ),
    );
    if (person != null && mounted) widget.onCreated?.call(person);
  }
}
