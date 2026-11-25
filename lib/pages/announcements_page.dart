import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/announcement_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_title.dart';
import 'announcement_page.dart';

/// The announcements, newest first. Opening it marks them all as seen.
class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  void _markSeen() {
    final latest = ref.read(announcementsProvider).value?.firstOrNull;
    if (latest != null) {
      ref.read(lastSeenAnnouncementProvider.notifier).markSeen(latest.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(announcementsProvider, (_, _) => _markSeen());
    final items = ref.watch(announcementsProvider);
    // Already loaded at startup: seen as soon as the page shows.
    if (items.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markSeen();
      });
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(announcementsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const PageTitle(
              'Announcements',
              belowCloseButton: true,
              horizontalPadding: 0,
            ),
            ...switch (items) {
              AsyncError(:final error) => [
                EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load announcements',
                  subtitle: '$error',
                ),
              ],
              AsyncData(value: []) => const [
                EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                ),
              ],
              AsyncData(:final value) => [
                for (final a in value)
                  Card(
                    child: ListTile(
                      title: Text(a.title),
                      subtitle: Text(DateFormat.yMMMd().format(a.date)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute<void>(builder: (_) => AnnouncementPage(a)),
                      ),
                    ),
                  ),
              ],
              _ => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}
