import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/fab_hero_tags.dart';
import '../core/theme.dart';
import '../models/sync_progress.dart';
import '../providers/backup_providers.dart';
import '../providers/sync_providers.dart';
import '../services/backup_service.dart';
import '../services/cloud_backup_client.dart';
import '../services/local_backup_store.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';
import '../widgets/sync_progress_indicator.dart';

final _dateFormat = DateFormat('d MMM yyyy, HH:mm');

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _errorText(Object e) => e is BackupException ? e.message : '$e';

/// Where and how often the logbook is backed up, and restoring from backups.
class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Drop messages from before the page was opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backupNoticeProvider.notifier).clear();
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLocalInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Local backups'),
        content: const Text(
          'Backups on this device are deleted if Zenith is uninstalled. '
          'Open "Backups on this device" to save a copy somewhere else.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _backUp(BackupDestination destination) async {
    try {
      await ref.read(backupControllerProvider.notifier).backUp(destination);
      _snack('Backup complete');
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  Future<void> _connect(BackupDestination d) async {
    try {
      await ref.read(cloudAuthProvider(d).notifier).login();
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  Future<void> _disconnect(BackupDestination d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect ${d.label}?'),
        content: Text(
          'Automatic backups and sync with ${d.label} will stop. Backups '
          'already in your ${d.label} are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(cloudAuthProvider(d).notifier).logout();
  }

  /// Confirms, then restores the backup that [load] returns, with a blocking
  /// progress dialog in between.
  Future<void> _restore({
    required DateTime createdAt,
    required Future<Uint8List?> Function() load,
    bool confirm = true,
  }) async {
    if (confirm && !await _confirmRestore(createdAt)) return;
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Restoring backup'),
            content: Consumer(
              builder: (context, ref, _) => SyncProgressIndicator(
                progress:
                    ref.watch(
                      backupControllerProvider.select((s) => s.value?.restore),
                    ) ??
                    const SyncProgress(
                      SyncPhase.saving,
                      message: 'Restoring backup…',
                    ),
              ),
            ),
          ),
        ),
      ).whenComplete(() => dialogOpen = false),
    );

    try {
      final bytes = await load();
      if (bytes == null) return;
      final s = await ref
          .read(backupControllerProvider.notifier)
          .restore(bytes);
      _snack(
        'Restored ${s.flights} flights, ${s.aircraft} aircraft '
        'and ${s.people} people',
      );
    } catch (e) {
      _snack(_errorText(e));
    } finally {
      if (dialogOpen) navigator.pop();
    }
  }

  Future<bool> _confirmRestore(DateTime createdAt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore),
        title: const Text('Restore backup?'),
        content: Text(
          'All Zenith data on this device (flights, aircraft, people, '
          'airports and aircraft types) will be replaced with the backup '
          'from ${_dateFormat.format(createdAt)}.\n\n'
          'A copy of your current data is saved to the backups on this '
          'device first, so you can undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
    final DateTime createdAt;
    try {
      final header = await BackupService.readHeader(bytes);
      createdAt =
          DateTime.tryParse(header['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now();
    } catch (e) {
      _snack(_errorText(e));
      return;
    }
    await _restore(createdAt: createdAt, load: () async => bytes);
  }

  Future<void> _showCloudBackups(BackupDestination d) async {
    final picked = await showModalBottomSheet<RemoteBackup>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CloudBackupsSheet(d),
    );
    if (picked == null) return;
    await _restore(
      createdAt: picked.createdAt,
      load: () => ref
          .read(backupControllerProvider.notifier)
          .downloadFromCloud(d, picked),
    );
  }

  List<Widget> _cloudSection(
    BackupDestination d,
    BackupState backupState,
    BackupSettings settings,
  ) {
    final auth = ref.watch(cloudAuthProvider(d));
    final connected = auth.value ?? false;
    return [
      SectionHeader(title: d.label, uppercase: true),
      Card(
        child: Column(
          children: [
            _CloudAccountTile(
              destination: d,
              auth: auth,
              onConnect: () => _connect(d),
              onDisconnect: () => _disconnect(d),
            ),
            if (connected) ...[
              const Divider(height: 1, indent: 72),
              _BackupNowTile(
                status: backupState.statusOf(d),
                progress: backupState.running[d],
                enabled: !backupState.restoring,
                onTap: () => _backUp(d),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Icon(
                  Icons.cloud_download_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Restore from ${d.label}'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !backupState.busy,
                onTap: () => _showCloudBackups(d),
              ),
              ..._syncTiles(d, settings.of(d).sync),
              ..._destinationSettings(d, settings.of(d)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  /// Whether the logbook syncs through [d], and how the last sync went.
  List<Widget> _syncTiles(BackupDestination d, bool on) {
    final theme = Theme.of(context);
    final status = ref.watch(syncControllerProvider)[d] ?? const SyncStatus();
    final last = status.lastSyncAt;
    Future<void> syncNow() async {
      try {
        await ref.read(syncControllerProvider.notifier).syncNow(d);
      } catch (e) {
        _snack(_errorText(e));
      }
    }

    return [
      const Divider(height: 1, indent: 72),
      SwitchListTile(
        secondary: Icon(Icons.sync, color: theme.colorScheme.primary),
        title: const Text('Sync across devices'),
        value: on,
        onChanged: (v) async {
          await ref.read(backupSettingsProvider.notifier).setSync(d, v);
          if (v) await syncNow();
        },
      ),
      if (on) ...[
        const Divider(height: 1, indent: 72),
        ListTile(
          leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
          title: const Text('Sync now'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status.running)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(),
                )
              else
                Text(
                  last == null
                      ? 'Not synced yet'
                      : 'Last sync: ${_dateFormat.format(last)}',
                ),
              if (status.lastError != null && !status.running)
                Text(
                  status.lastError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
          enabled: !status.running,
          onTap: syncNow,
        ),
      ],
      const Divider(height: 1, indent: 72),
      ListTile(
        leading: Icon(Icons.delete_sweep, color: theme.colorScheme.error),
        title: const Text('Delete sync data'),
        enabled: !status.running,
        onTap: () => _deleteSyncData(d),
      ),
    ];
  }

  Future<void> _deleteSyncData(BackupDestination d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep),
        title: const Text('Delete sync data?'),
        content: Text(
          'Sync is turned off on this device and the Zenith Sync folder in '
          '${d.label} is emptied. The logbook on your devices is not '
          'touched.\n\n'
          'Other devices that still sync with this ${d.label} upload their '
          'data again: turn sync off on them first to keep the folder empty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(syncControllerProvider.notifier).deleteSyncData(d);
      _snack('Sync data deleted from ${d.label}');
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  /// Frequency, crew photos and retention of one destination.
  List<Widget> _destinationSettings(
    BackupDestination d,
    DestinationSettings s,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(backupSettingsProvider.notifier);
    return [
      const Divider(height: 1, indent: 72),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Automatic Backups', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<BackupFrequency>(
                showSelectedIcon: false,
                segments: [
                  for (final f in BackupFrequency.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {s.frequency},
                onSelectionChanged: (v) => notifier.setFrequency(d, v.first),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, indent: 72),
      SwitchListTile(
        secondary: Icon(
          Icons.photo_library_outlined,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Include crew photos'),
        subtitle: const Text('Makes backups larger.'),
        value: s.includePhotos,
        onChanged: (v) => notifier.setIncludePhotos(d, v),
      ),
      const Divider(height: 1, indent: 72),
      ListTile(
        leading: Icon(Icons.history, color: theme.colorScheme.primary),
        title: const Text('Backups to keep'),
        subtitle: Text('Last ${s.keep}, older ones are deleted'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _chooseKeep(d, s.keep),
      ),
    ];
  }

  Future<void> _chooseKeep(BackupDestination d, int current) async {
    const custom = 0;
    final isCustom = !DestinationSettings.keepChoices.contains(current);
    var chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Backups to keep on ${d.label}'),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
        content: RadioGroup<int>(
          groupValue: isCustom ? custom : current,
          onChanged: (value) => Navigator.pop(ctx, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final n in DestinationSettings.keepChoices)
                RadioListTile<int>(value: n, title: Text('Last $n')),
              RadioListTile<int>(
                value: custom,
                title: Text(isCustom ? 'Custom (last $current)' : 'Custom'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (chosen == custom && mounted) {
      chosen = await showDialog<int>(
        context: context,
        builder: (_) => _CustomKeepDialog(initial: current),
      );
    }
    if (chosen == null || chosen == current) return;
    await ref.read(backupSettingsProvider.notifier).setKeep(d, chosen);
  }

  Future<void> _showLocalBackups() async {
    final action = await showModalBottomSheet<(_LocalAction, LocalBackup)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _LocalBackupsSheet(),
    );
    if (action == null) return;
    final (kind, backup) = action;
    switch (kind) {
      case _LocalAction.restore:
        await _restore(
          createdAt: backup.createdAt,
          load: backup.file.readAsBytes,
        );
      case _LocalAction.saveAs:
        try {
          final saved = await ref
              .read(localBackupStoreProvider)
              .exportCopy(backup.file);
          if (saved) _snack('Backup saved');
        } catch (e) {
          _snack('Could not save the backup: $e');
        }
      case _LocalAction.share:
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(backup.file.path, mimeType: BackupService.mimeType)],
            subject: 'Zenith backup',
          ),
        );
      case _LocalAction.delete:
        await backup.file.delete();
        ref.invalidate(localBackupsProvider);
        _snack('Backup deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupNoticeProvider, (_, message) {
      if (message == null) return;
      _snack(message);
      ref.read(backupNoticeProvider.notifier).clear();
    });

    final settings = ref.watch(backupSettingsProvider).value;
    final backupState =
        ref.watch(backupControllerProvider).value ?? const BackupState();
    final localCount = ref.watch(localBackupsProvider).value?.length;

    if (settings == null) {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        floatingActionButton: FloatingActionButton(
          heroTag: closeFabHeroTag,
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            'Backup',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          // ---------------------------------------------------------------
          SectionHeader(
            title: 'Local',
            uppercase: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: 'About local backups',
              visualDensity: VisualDensity.compact,
              onPressed: _showLocalInfo,
            ),
          ),
          Card(
            child: Column(
              children: [
                _BackupNowTile(
                  status: backupState.statusOf(BackupDestination.local),
                  progress: backupState.running[BackupDestination.local],
                  enabled: !backupState.restoring,
                  onTap: () => _backUp(BackupDestination.local),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(
                    Icons.folder_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Backups on this device'),
                  subtitle: Text(switch (localCount) {
                    null => 'Loading…',
                    0 => 'None yet',
                    1 => '1 backup',
                    final n => '$n backups',
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !backupState.busy,
                  onTap: _showLocalBackups,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(
                    Icons.file_open_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Restore from file'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !backupState.busy,
                  onTap: _restoreFromFile,
                ),
                ..._destinationSettings(
                  BackupDestination.local,
                  settings.of(BackupDestination.local),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------------------------------------------------------------
          for (final d in BackupDestination.cloud)
            ..._cloudSection(d, backupState, settings),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _CloudAccountTile extends ConsumerWidget {
  const _CloudAccountTile({
    required this.destination,
    required this.auth,
    required this.onConnect,
    required this.onDisconnect,
  });

  final BackupDestination destination;
  final AsyncValue<bool> auth;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connected = auth.value ?? false;
    final account = connected
        ? ref.watch(cloudAccountProvider(destination)).value
        : null;

    return ListTile(
      leading: Icon(
        connected ? Icons.cloud_done_outlined : Icons.cloud_outlined,
        color: connected
            ? context.appColors.success
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(destination.label),
      // One line: a long email shrinks to fit instead of wrapping.
      subtitle: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          auth.isLoading
              ? 'Checking…'
              : !connected
              ? 'Not connected'
              : account == null
              ? 'Connected'
              : account.email.isNotEmpty
              ? account.email
              : account.name,
          maxLines: 1,
          softWrap: false,
        ),
      ),
      trailing: auth.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : connected
          ? TextButton(
              onPressed: onDisconnect,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Disconnect'),
            )
          : FilledButton.tonal(
              onPressed: onConnect,
              child: const Text('Connect'),
            ),
    );
  }
}

class _BackupNowTile extends StatelessWidget {
  const _BackupNowTile({
    required this.status,
    required this.progress,
    required this.enabled,
    required this.onTap,
  });

  final DestinationStatus status;

  /// Where the backup is at while one is running.
  final SyncProgress? progress;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = status.lastBackupAt;
    final progress = this.progress;
    final running = progress != null;
    return ListTile(
      leading: Icon(
        Icons.backup_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Back up now'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (running)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SyncProgressIndicator(progress: progress, compact: true),
            )
          else
            Text(
              last == null
                  ? 'No backups yet'
                  : 'Last backup: ${_dateFormat.format(last)}',
            ),
          if (status.lastError != null && !running)
            Text(
              status.lastError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
      enabled: enabled && !running,
      onTap: onTap,
    );
  }
}

class _CloudBackupsSheet extends ConsumerWidget {
  const _CloudBackupsSheet(this.destination);
  final BackupDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backups = ref.watch(cloudBackupsProvider(destination));
    return _BackupsSheet(
      title: '${destination.label} backups',
      emptyText: 'No backups in your ${destination.label} yet.',
      items: backups,
      onRetry: () => ref.invalidate(cloudBackupsProvider(destination)),
      itemBuilder: (b) => ListTile(
        leading: Icon(
          Icons.cloud_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(_dateFormat.format(b.createdAt)),
        subtitle: Text(_formatSize(b.size)),
        trailing: const Icon(Icons.restore),
        onTap: () => Navigator.pop(context, b),
      ),
    );
  }
}

enum _LocalAction { restore, saveAs, share, delete }

class _LocalBackupsSheet extends ConsumerWidget {
  const _LocalBackupsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backups = ref.watch(localBackupsProvider);
    return _BackupsSheet(
      title: 'Backups on this device',
      emptyText: 'No backups on this device yet.',
      items: backups,
      onRetry: () => ref.invalidate(localBackupsProvider),
      itemBuilder: (b) => ListTile(
        leading: Icon(
          b.isPreRestore ? Icons.settings_backup_restore : Icons.save_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(_dateFormat.format(b.createdAt)),
        subtitle: Text(
          b.isPreRestore
              ? '${_formatSize(b.size)} · Before restore'
              : _formatSize(b.size),
        ),
        trailing: PopupMenuButton<_LocalAction>(
          onSelected: (action) => Navigator.pop(context, (action, b)),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _LocalAction.restore,
              child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('Restore'),
              ),
            ),
            PopupMenuItem(
              value: _LocalAction.saveAs,
              child: ListTile(
                leading: Icon(Icons.save_alt),
                title: Text('Save to…'),
              ),
            ),
            PopupMenuItem(
              value: _LocalAction.share,
              child: ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Share'),
              ),
            ),
            PopupMenuItem(
              value: _LocalAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.pop(context, (_LocalAction.restore, b)),
      ),
    );
  }
}

/// Shared layout of the backup pickers.
class _BackupsSheet<T> extends StatelessWidget {
  const _BackupsSheet({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.itemBuilder,
    required this.onRetry,
  });

  final String title;
  final String emptyText;
  final AsyncValue<List<T>> items;
  final Widget Function(T) itemBuilder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          Flexible(
            child: items.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                // heightFactor keeps Center from filling the sheet's 70% max height.
                child: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorText(e),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [for (final item in list) itemBuilder(item)],
                    ),
            ),
          ),
          SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

/// Asks for how many backups to keep.
class _CustomKeepDialog extends StatefulWidget {
  const _CustomKeepDialog({required this.initial});
  final int initial;

  @override
  State<_CustomKeepDialog> createState() => _CustomKeepDialogState();
}

class _CustomKeepDialogState extends State<_CustomKeepDialog> {
  late final _controller = TextEditingController(
    text: widget.initial.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    const min = DestinationSettings.keepMin;
    const max = DestinationSettings.keepMax;
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < min || value > max) {
      setState(() => _error = 'Between $min and $max');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backups to Keep'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Most recent backups to keep',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
