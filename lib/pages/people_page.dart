import 'package:flutter/material.dart';

import '../core/app_page_route.dart';
import '../widgets/people_list_scaffold.dart';
import 'person_detail_page.dart';

/// The people you fly with. Tap one to open their profile.
class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PeopleListScaffold(
      title: 'People',
      onTap: (entry) => Navigator.push(
        context,
        AppPageRoute<void>(
          builder: (_) =>
              PersonDetailPage(personId: entry.person.id, initial: entry),
        ),
      ),
    );
  }
}
