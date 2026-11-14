import 'dart:io';

import 'package:flutter/services.dart';

import 'backup_service.dart';

/// A backup file kept on this device.
class LocalBackup {
  const LocalBackup({
    required this.file,
    required this.size,
    required this.createdAt,
  });
  final File file;
  final int size;
  final DateTime createdAt;

  String get name => file.uri.pathSegments.last;

  /// Safety copies taken automatically right before a restore.
  bool get isPreRestore => name.contains(LocalBackupStore.preRestoreSuffix);
}

/// Backups stored in `<app support>/backups/`, plus the system file pickers
/// used to copy a backup out of the app or bring one in.
class LocalBackupStore {
  LocalBackupStore(this._root);
  final Future<Directory> Function() _root;

  static const preRestoreSuffix = '_pre-restore';
  static const _channel = MethodChannel('zenith/backup_files');

  Future<Directory> get directory async {
    final dir = Directory('${(await _root()).path}/backups');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Newest first.
  Future<List<LocalBackup>> list() async {
    final dir = await directory;
    final backups = <LocalBackup>[];
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!BackupService.isBackupFileName(name)) continue;
      final stat = file.statSync();
      backups.add(
        LocalBackup(
          file: file,
          size: stat.size,
          createdAt: BackupService.timeFromFileName(name) ?? stat.modified,
        ),
      );
    }
    return backups..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<File> save(BackupSnapshot snapshot, {bool preRestore = false}) async {
    final name = BackupService.fileNameFor(
      snapshot.createdAt,
      suffix: preRestore ? preRestoreSuffix : '',
    );
    final file = File('${(await directory).path}/$name');
    await file.writeAsBytes(snapshot.bytes, flush: true);
    return file;
  }

  /// Keeps the newest [keep] regular backups and the newest [keep] safety
  /// copies; deletes the rest.
  Future<void> prune({required int keep}) async {
    final all = await list();
    final regular = all.where((b) => !b.isPreRestore).skip(keep);
    final safety = all.where((b) => b.isPreRestore).skip(keep);
    for (final old in [...regular, ...safety]) {
      await old.file.delete();
    }
  }

  /// Lets the user choose where to save a copy of [file] (Downloads, a USB
  /// drive, another cloud app...). Returns false if they cancelled.
  Future<bool> exportCopy(File file) async {
    final saved = await _channel.invokeMethod<bool>('saveAs', {
      'path': file.path,
      'name': file.uri.pathSegments.last,
      'mimeType': BackupService.mimeType,
    });
    return saved ?? false;
  }

  /// Lets the user pick a backup file from anywhere on the device. Returns
  /// its bytes, or null if they cancelled.
  Future<Uint8List?> pickFile() async {
    final path = await _channel.invokeMethod<String>('pick');
    if (path == null) return null;
    final file = File(path);
    try {
      return await file.readAsBytes();
    } finally {
      if (file.existsSync()) await file.delete();
    }
  }
}
