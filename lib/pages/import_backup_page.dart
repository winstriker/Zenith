import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/fab_hero_tags.dart';
import '../models/sync_progress.dart';
import '../providers/backup_providers.dart';
import '../providers/user_provider.dart';
import '../services/backup_service.dart';
import '../services/cloud_backup_client.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';
import '../widgets/sync_progress_indicator.dart';

final _dateFormat = DateFormat('d MMM yyyy, HH:mm');

String _errorText(Object e) => e is BackupException ? e.message : '$e';

/// Onboarding's alternative to starting fresh: restore an existing backup
/// from a file or a connected cloud provider. Pops `true` to go back and
/// start fresh instead; a successful restore completes onboarding, which
/// swaps the whole app over to the main shell on its own.
class ImportBackupPage extends ConsumerStatefulWidget {
  const ImportBackupPage({super.key});

  @override
  ConsumerState<ImportBackupPage> createState() => _ImportBackupPageState();
}

class _ImportBackupPageState extends ConsumerState<ImportBackupPage> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restoreBytes(Uint8List bytes) async {
    try {
      await ref.read(backupControllerProvider.notifier).restore(bytes);
      await ref.read(onboardingCompleteProvider.notifier).setComplete();
      // The app has already swapped its home to the main shell underneath;
      // closing this page is what reveals it.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  Future<void> _restoreFromFile() async {
    final Uint8List? bytes;
    try {
      bytes = await ref.read(localBackupStoreProvider).pickFile();
    } catch (e) {
      _snack('Could not open the file: $e');
      return;
    }
    if (bytes == null) return;
    setState(() => _busy = true);
    await _restoreBytes(bytes);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _connect(BackupDestination d) async {
    try {
      await ref.read(cloudAuthProvider(d).notifier).login();
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  Future<void> _browseCloud(BackupDestination d) async {
    final picked = await showModalBottomSheet<RemoteBackup>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CloudBackupsSheet(d),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(backupControllerProvider.notifier)
          .downloadFromCloud(d, picked);
      await _restoreBytes(bytes);
    } catch (e) {
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _cloudSection(BackupDestination d) {
    final auth = ref.watch(cloudAuthProvider(d));
    final connected = auth.value ?? false;
    return [
      SectionHeader(title: d.label, uppercase: true),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                connected ? Icons.cloud_done_outlined : Icons.cloud_outlined,
              ),
              title: Text(connected ? 'Connected' : 'Not connected'),
              trailing: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : connected
                  ? const Icon(Icons.check_circle_outline)
                  : FilledButton.tonal(
                      onPressed: _busy ? null : () => _connect(d),
                      child: const Text('Connect'),
                    ),
            ),
            if (connected) ...[
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: Text('Restore from ${d.label}'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_busy,
                onTap: () => _browseCloud(d),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final restoreProgress = ref.watch(
      backupControllerProvider.select((s) => s.value?.restore),
    );

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const PageTitle(
            'Import Backup',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SyncProgressIndicator(
                progress:
                    restoreProgress ??
                    const SyncProgress(
                      SyncPhase.saving,
                      message: 'Restoring backup…',
                    ),
              ),
            ),
          const SectionHeader(title: 'Local', uppercase: true),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text('Import from file'),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_busy,
              onTap: _restoreFromFile,
            ),
          ),
          const SizedBox(height: 8),
          for (final d in BackupDestination.cloud) ..._cloudSection(d),
        ],
      ),
    );
  }
}

/// Picks a backup out of a cloud provider's list, newest first.
class _CloudBackupsSheet extends ConsumerWidget {
  const _CloudBackupsSheet(this.destination);
  final BackupDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final backups = ref.watch(cloudBackupsProvider(destination));
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              '${destination.label} backups',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: backups.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorText(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No backups in your ${destination.label} yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final b in list)
                          ListTile(
                            leading: const Icon(Icons.cloud_outlined),
                            title: Text(_dateFormat.format(b.createdAt)),
                            trailing: const Icon(Icons.restore),
                            onTap: () => Navigator.pop(context, b),
                          ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
