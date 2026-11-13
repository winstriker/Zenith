import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/person_providers.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/person_form_dialog.dart';
import '../widgets/person_tile.dart';

/// Lists people from the database, most recently flown with first, and pops
/// the chosen [Person]. People in [excludeIds] (already on the crew) are hidden.
class PersonSelectPage extends ConsumerStatefulWidget {
  const PersonSelectPage({
    super.key,
    required this.title,
    this.excludeIds,
    this.allowCreate = true,
  });
  final String title;
  final Set<int>? excludeIds;
  final bool allowCreate;

  @override
  ConsumerState<PersonSelectPage> createState() => _PersonSelectPageState();
}

class _PersonSelectPageState extends ConsumerState<PersonSelectPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.allowCreate)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Add new person',
              onPressed: _addPerson,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
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
              data: (all) {
                final people = all
                    .where((p) => !excluded.contains(p.person.id))
                    .toList();
                if (people.isEmpty) {
                  return EmptyState(
                    icon: _query.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                    iconSize: _query.isEmpty ? 64 : 48,
                    title: _query.isEmpty
                        ? 'No people yet'
                        : 'No people match "$_query"',
                    subtitle: _query.isEmpty
                        ? 'Add the people you fly with.'
                        : null,
                    action: widget.allowCreate
                        ? FilledButton.icon(
                            onPressed: _addPerson,
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Add Person'),
                          )
                        : null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: people.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) => PersonTile(
                    entry: people[i],
                    onTap: () => Navigator.pop(context, people[i].person),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPerson() async {
    final words = _query.split(RegExp(r'\s+'));
    final person = await showDialog<Person>(
      context: context,
      builder: (_) => PersonFormDialog(
        initialName: words.isNotEmpty ? words.first : '',
        initialSurname: words.length > 1 ? words.skip(1).join(' ') : '',
      ),
    );
    if (person != null && mounted) Navigator.pop(context, person);
  }
}
