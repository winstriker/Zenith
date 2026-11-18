import 'package:flutter/material.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../widgets/page_title.dart';
import 'pdf_export_settings_page.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

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
            'Export Data',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('PDF'),
              subtitle: const Text('2026 EASA Part-FCL compliant'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                AppPageRoute<void>(
                  builder: (_) => const PdfExportSettingsPage(),
                ),
              ),
            ),
          ),
          // shortcut: CSV/JSON have no export yet, so no page to open; add one when they're implemented.
          const Card(
            child: ListTile(
              enabled: false,
              leading: Icon(Icons.table_chart_outlined),
              title: Text('CSV'),
              subtitle: Text('Coming soon'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const Card(
            child: ListTile(
              enabled: false,
              leading: Icon(Icons.data_object),
              title: Text('JSON'),
              subtitle: Text('Coming soon'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}
