import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/fab_hero_tags.dart';
import '../providers/announcement_providers.dart';
import '../services/announcement_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_title.dart';

/// One announcement, its markdown rendered.
class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage(this.announcement, {super.key});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(announcementTextProvider(announcement));

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          PageTitle(
            announcement.title,
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          ...switch (text) {
            AsyncError(:final error) => [
              EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load the announcement',
                subtitle: '$error',
                action: FilledButton(
                  onPressed: () =>
                      ref.invalidate(announcementTextProvider(announcement)),
                  child: const Text('Retry'),
                ),
              ),
            ],
            AsyncData(:final value) => [
              MarkdownBody(
                data: value,
                onTapLink: (_, href, _) {
                  final uri = href == null ? null : Uri.tryParse(href);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
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
    );
  }
}
