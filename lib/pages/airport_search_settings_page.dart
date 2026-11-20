import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../providers/airport_providers.dart';
import '../services/database.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';

/// Which airports every airport search in the app finds: only those with an
/// ICAO code, and of which types.
class AirportSearchSettingsPage extends ConsumerWidget {
  const AirportSearchSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excluded = ref.watch(excludedAirportTypeNamesProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle(
            'Search Settings',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          const Text("App-Wise"),
          const SectionHeader(title: 'Codes', uppercase: true),
          Card(
            child: SwitchListTile(
              title: const Text('ICAO airports only'),
              subtitle: const Text('Your airports are always shown'),
              value: ref.watch(icaoOnlyProvider),
              onChanged: ref.read(icaoOnlyProvider.notifier).set,
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Airport types', uppercase: true),
          Card(
            child: Column(
              children: [
                for (final t in AirportType.values)
                  if (t != AirportType.undefined)
                    CheckboxListTile(
                      title: Text(AirportType.getDisplayName(t)),
                      value: !excluded.contains(t.name),
                      onChanged: (v) => ref
                          .read(excludedAirportTypeNamesProvider.notifier)
                          .setEnabled(t.name, enabled: v ?? true),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
