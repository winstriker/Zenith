import 'package:flutter/material.dart';

import '../services/database.dart';
import '../widgets/people_list_scaffold.dart';

/// Lists people from the database, most recently flown with first, and pops
/// the chosen [Person]. People in [excludeIds] (already on the crew) are hidden.
class PersonSelectPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PeopleListScaffold(
      title: title,
      excludeIds: excludeIds,
      allowCreate: allowCreate,
      autofocusSearch: true,
      onTap: (entry) => Navigator.pop(context, entry.person),
      // A person created from the picker is the one being picked.
      onCreated: (person) => Navigator.pop(context, person),
    );
  }
}
