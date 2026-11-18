import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../models/sync_progress.dart';
import '../providers/update_providers.dart';
import '../widgets/page_title.dart';
import '../widgets/sync_progress_indicator.dart';

class UpdatesPage extends ConsumerWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final status = ref.watch(updateProvider);
    final updates = ref.read(updateProvider.notifier);
    final progress = status.progress;
    final busy = progress.isRunning;

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
            'Version',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.flight_takeoff, color: primary),
                  title: const Text('Zenith'),
                  subtitle: const Text('Version $appBuildName'),
                  trailing: status.release != null && !busy
                      ? FilledButton.tonal(
                          onPressed: updates.install,
                          child: const Text('Install'),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Check for updates',
                          onPressed: busy ? null : updates.check,
                        ),
                  onTap: busy ? null : updates.check,
                ),
                if (progress.phase != SyncPhase.idle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    // Done has no bar: the shared indicator would spin one.
                    child: progress.phase == SyncPhase.done
                        ? Text(
                            progress.message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          )
                        : SyncProgressIndicator(progress: progress),
                  ),
                if (status.release?.notes case final notes?
                    when notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's new",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(notes),
                      ],
                    ),
                  ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  secondary: Icon(Icons.update, color: primary),
                  title: const Text('Check at startup'),
                  value: ref.watch(autoUpdateCheckProvider),
                  onChanged: ref.read(autoUpdateCheckProvider.notifier).set,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
