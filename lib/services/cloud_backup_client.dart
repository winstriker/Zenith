import 'dart:typed_data';

import 'backup_service.dart';

/// A backup file stored with a cloud provider.
class RemoteBackup {
  const RemoteBackup({
    required this.name,
    required this.id,
    required this.size,
    required this.createdAt,
  });
  final String name;

  /// What the provider uses to address the file (a path for Dropbox, a file
  /// id for Google Drive).
  final String id;
  final int size;
  final DateTime createdAt;
}

/// The account a cloud provider is connected to.
class CloudAccount {
  const CloudAccount({required this.name, required this.email});
  final String name;
  final String email;
}

/// The cloud session is no longer usable (revoked, expired or missing
/// permissions); the user has to connect again.
class CloudReauthRequired extends BackupException {
  const CloudReauthRequired(super.message);
}

/// Called during a transfer with the fraction done, from 0 to 1.
typedef TransferProgress = void Function(double fraction);

/// What the backup controller needs from a cloud provider. Every backup
/// lives in a single folder owned by the app.
abstract interface class CloudBackupClient {
  Future<CloudAccount> currentAccount();

  Future<void> upload(
    String name,
    Uint8List bytes, {
    TransferProgress? onProgress,
  });

  /// Backups in the folder, newest first.
  Future<List<RemoteBackup>> list();

  /// [size] stands in for the length when the provider doesn't send one.
  Future<Uint8List> download(
    String id, {
    int? size,
    TransferProgress? onProgress,
  });

  Future<void> delete(String id);

  /// Keeps the newest [keep] backups and deletes the rest.
  Future<void> prune({required int keep});

  /// Invalidates the tokens on the provider's side. Best effort.
  Future<void> revoke();
}
