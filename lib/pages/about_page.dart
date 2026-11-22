import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../models/sync_progress.dart';
import '../providers/backup_providers.dart';
import '../providers/update_providers.dart';
import '../services/backup_service.dart';
import '../services/update_service.dart';
import '../widgets/page_title.dart';
import '../widgets/sync_progress_indicator.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final status = ref.watch(updateProvider);
    final updates = ref.read(updateProvider.notifier);
    final progress = status.progress;
    final backingUp = ref.watch(backupControllerProvider).value?.busy ?? false;
    final busy = progress.isRunning || backingUp;

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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Plain Row, not ListTile: ListTile shrinks a large leading
                // and pins text to baselines instead of centering it.
                InkWell(
                  onTap: busy || !canSelfUpdate ? null : updates.check,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/zenith_logo.png',
                            width: 56,
                            height: 56,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zenith',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Version $appBuildName',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (canSelfUpdate)
                          status.release != null && !busy
                              ? FilledButton.tonal(
                                  onPressed: () =>
                                      _backUpAndInstall(context, ref),
                                  child: const Text('Install'),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Check for updates',
                                  onPressed: busy ? null : updates.check,
                                ),
                      ],
                    ),
                  ),
                ),
                if (backingUp)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SyncProgressIndicator(
                      progress: SyncProgress(
                        SyncPhase.saving,
                        message: 'Backing up before updating…',
                      ),
                    ),
                  )
                else if (progress.phase != SyncPhase.idle)
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
                if (canSelfUpdate) ...[
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    secondary: Icon(Icons.update, color: primary),
                    title: const Text('Check at startup'),
                    value: ref.watch(autoUpdateCheckProvider),
                    onChanged: ref.read(autoUpdateCheckProvider.notifier).set,
                  ),
                ],
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: primary),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute<void>(
                      builder: (_) => const LicensePage(
                        applicationVersion: 'v$appBuildName',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Backs up the logbook and lets the user save a copy before installing,
  /// so an update gone wrong can't cost them their data.
  Future<void> _backUpAndInstall(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    void snack(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));
    try {
      await ref
          .read(backupControllerProvider.notifier)
          .backUp(BackupDestination.local);
      final store = ref.read(localBackupStoreProvider);
      final latest = (await store.list()).where((b) => !b.isPreRestore);
      if (latest.isEmpty || !await store.exportCopy(latest.first.file)) {
        snack('Save the backup to install the update');
        return;
      }
    } catch (e) {
      snack(
        'Backup failed, update not installed: '
        '${e is BackupException ? e.message : e}',
      );
      return;
    }
    await ref.read(updateProvider.notifier).install();
  }
}
