import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'backup_service.dart';
import 'cloud_backup_client.dart';
import 'oauth_service.dart';

/// Minimal Google Drive API v3 client for backup files.
///
/// Uses the `drive.file` scope, so Zenith only sees the files and folders it
/// created itself. Backups go to a [folderName] folder in "My Drive", which
/// the user can see, move or rename; it is found again by name.
class GoogleDriveClient implements CloudBackupClient {
  GoogleDriveClient(this._auth, {this.chunkSize = 4 * 1024 * 1024});

  final OAuthService _auth;
  static final _log = Logger('GoogleDriveClient');

  static const folderName = 'Zenith Backups';
  static const revokeEndpoint = 'https://oauth2.googleapis.com/revoke';
  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const _folderMime = 'application/vnd.google-apps.folder';

  /// Size of each request body when uploading. Google requires a multiple
  /// of 256 KiB for every chunk but the last.
  final int chunkSize;

  @override
  Future<CloudAccount> currentAccount() async {
    final res = await _call(
      'GET',
      _apiUri('about', {'fields': 'user(displayName,emailAddress)'}),
    );
    final user =
        (jsonDecode(res.body) as Map<String, dynamic>)['user']
            as Map<String, dynamic>?;
    return CloudAccount(
      name: user?['displayName'] as String? ?? '',
      email: user?['emailAddress'] as String? ?? '',
    );
  }

  /// Uploads through a resumable session rather than a single request.
  ///
  /// The session is opened with just the metadata, so a rejection (expired
  /// token, full Drive) comes back readable instead of as a connection reset
  /// halfway through a large body. The data then goes up in chunks of
  /// [chunkSize].
  @override
  Future<void> upload(String name, Uint8List bytes) async {
    final folderId = await _folderId(create: true);
    final start = await _call(
      'POST',
      Uri.parse(
        '$_uploadApi/files',
      ).replace(queryParameters: {'uploadType': 'resumable', 'fields': 'id'}),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': BackupService.mimeType,
        'X-Upload-Content-Length': '${bytes.length}',
      },
      body: jsonEncode({
        'name': name,
        'parents': [folderId],
      }),
    );
    final location = start.headers['location'];
    if (location == null) {
      throw const BackupException(
        'Google Drive did not start the upload. Try again.',
      );
    }
    final session = Uri.parse(location);

    final total = bytes.length;
    if (total == 0) {
      await _call(
        'PUT',
        session,
        headers: {'Content-Range': 'bytes */0'},
        body: Uint8List(0),
      );
      return;
    }

    var offset = 0;
    while (true) {
      final end = (offset + chunkSize).clamp(0, total);
      final res = await _call(
        'PUT',
        session,
        headers: {
          'Content-Type': BackupService.mimeType,
          'Content-Range': 'bytes $offset-${end - 1}/$total',
        },
        body: Uint8List.sublistView(bytes, offset, end),
        accept: const {308},
      );
      if (res.statusCode != 308) return;
      // "Resume incomplete": continue from what Google actually stored.
      final range = RegExp(
        r'bytes=0-(\d+)',
      ).firstMatch(res.headers['range'] ?? '');
      offset = range == null ? 0 : int.parse(range.group(1)!) + 1;
      if (offset >= total) {
        throw const BackupException(
          'Google Drive did not finish the upload. Try again.',
        );
      }
    }
  }

  @override
  Future<List<RemoteBackup>> list() async {
    final folderId = await _folderId(create: false);
    if (folderId == null) return [];

    final files = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final res = await _call(
        'GET',
        _apiUri('files', {
          'q': "'$folderId' in parents and trashed = false",
          'fields': 'nextPageToken,files(id,name,size,createdTime)',
          'pageSize': '1000',
          'spaces': 'drive',
          'pageToken': ?pageToken,
        }),
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      files.addAll((json['files'] as List).cast<Map<String, dynamic>>());
      pageToken = json['nextPageToken'] as String?;
    } while (pageToken != null);

    return [
      for (final f in files)
        if (BackupService.isBackupFileName(f['name'] as String))
          RemoteBackup(
            name: f['name'] as String,
            id: f['id'] as String,
            // Drive reports sizes as strings.
            size: int.tryParse('${f['size'] ?? ''}') ?? 0,
            createdAt:
                BackupService.timeFromFileName(f['name'] as String) ??
                DateTime.parse(f['createdTime'] as String).toLocal(),
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Uint8List> download(String id) async {
    final res = await _call('GET', _apiUri('files/$id', {'alt': 'media'}));
    return res.bodyBytes;
  }

  @override
  Future<void> delete(String id) async {
    await _call('DELETE', _apiUri('files/$id'));
  }

  @override
  Future<void> prune({required int keep}) async {
    final backups = await list();
    for (final old in backups.skip(keep)) {
      await delete(old.id);
    }
  }

  @override
  Future<void> revoke() => _auth.revokeToken(revokeEndpoint);

  /// The backup folder's id, oldest match first. Looked up every time, as the
  /// user may trash it or the app may be reconnected to another account.
  Future<String?> _folderId({required bool create}) async {
    final res = await _call(
      'GET',
      _apiUri('files', {
        'q':
            "name = '$folderName' and mimeType = '$_folderMime' "
            'and trashed = false',
        'fields': 'files(id)',
        'orderBy': 'createdTime',
        'pageSize': '1',
        'spaces': 'drive',
      }),
    );
    final found = (jsonDecode(res.body) as Map<String, dynamic>)['files'];
    if (found is List && found.isNotEmpty) {
      return (found.first as Map<String, dynamic>)['id'] as String;
    }
    if (!create) return null;

    final created = await _call(
      'POST',
      _apiUri('files', {'fields': 'id'}),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': folderName, 'mimeType': _folderMime}),
    );
    return (jsonDecode(created.body) as Map<String, dynamic>)['id'] as String;
  }

  static Uri _apiUri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_api/$path').replace(queryParameters: query);

  /// Sends an authenticated request; anything but 2xx (or a status listed in
  /// [accept]) becomes a [BackupException].
  Future<http.Response> _call(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Set<int> accept = const {},
  }) async {
    final http.Response res;
    try {
      res = await _auth.send(method, url, headers: headers, body: body);
    } on OAuthException {
      // The refresh token was rejected; OAuthService already logged out.
      throw const CloudReauthRequired(
        'Your Google Drive session expired. Connect Google Drive again.',
      );
    }
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (ok || accept.contains(res.statusCode)) return res;

    var message = '';
    final reasons = <String>{};
    try {
      final error =
          (jsonDecode(res.body) as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      message = error['message'] as String? ?? '';
      for (final e in (error['errors'] as List? ?? const [])) {
        final reason = (e as Map<String, dynamic>)['reason'];
        if (reason is String) reasons.add(reason);
      }
      final status = error['status'];
      if (status is String) reasons.add(status);
      for (final d in (error['details'] as List? ?? const [])) {
        final reason = (d as Map<String, dynamic>)['reason'];
        if (reason is String) reasons.add(reason);
      }
    } catch (_) {
      message = res.body;
    }

    if (res.statusCode == 401) {
      throw const CloudReauthRequired(
        'Google Drive access was revoked. Connect Google Drive again.',
      );
    }
    if (reasons.contains('storageQuotaExceeded')) {
      throw const BackupException('Your Google Drive is full.');
    }
    if (reasons.contains('insufficientPermissions') ||
        reasons.contains('ACCESS_TOKEN_SCOPE_INSUFFICIENT')) {
      throw const CloudReauthRequired(
        'Zenith needs permission to store backups in your Google Drive. '
        'Connect Google Drive again and allow access.',
      );
    }
    if (reasons.contains('accessNotConfigured') ||
        reasons.contains('SERVICE_DISABLED')) {
      throw const BackupException(
        "The Google Drive API is not enabled in Zenith's Google Cloud "
        'project. Enable it in the Google Cloud Console (APIs & Services), '
        'then try again.',
      );
    }
    if (res.statusCode == 429 ||
        reasons.contains('rateLimitExceeded') ||
        reasons.contains('userRateLimitExceeded')) {
      throw const BackupException(
        'Google Drive is rate limiting requests. Try again in a few minutes.',
      );
    }

    final endpoint = url.path.replaceFirst(RegExp('^(/upload)?/drive/v3/'), '');
    _log.warning(
      'Google Drive $method $endpoint failed (${res.statusCode}): ${res.body}',
    );
    final details = message.trim().isEmpty ? res.body.trim() : message.trim();
    throw BackupException(
      'Google Drive error (${res.statusCode}) on $endpoint: '
      '${details.length > 300 ? '${details.substring(0, 300)}…' : details}',
    );
  }
}
