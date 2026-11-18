import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/fab_hero_tags.dart';
import '../widgets/page_title.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          const PageTitle(
            'About',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.flight_takeoff,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Zenith'),
              subtitle: const Text('Version $appBuildName'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Description'),
              subtitle: const Text('Pilot\'s Logbook'),
            ),
          ),
        ],
      ),
    );
  }
}
