import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/person_providers.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/person_form_dialog.dart';
import '../widgets/person_tile.dart';
import 'person_detail_page.dart';

/// The people you fly with. Tap one to open their profile.
class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add person',
            onPressed: _add,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search, size: 20),
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
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (people) {
                if (people.isEmpty) {
                  return _query.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: 'No people yet',
                          subtitle:
                              'People you add as crew on a flight appear here.',
                          action: FilledButton.icon(
                            onPressed: _add,
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Add Person'),
                          ),
                        )
                      : EmptyState(
                          icon: Icons.search_off,
                          iconSize: 48,
                          title: 'No people match "$_query"',
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: people.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final entry = people[i];
                    return PersonTile(
                      entry: entry,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PersonDetailPage(personId: entry.person.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    await showDialog<Person>(
      context: context,
      builder: (_) => const PersonFormDialog(),
    );
  }
}
