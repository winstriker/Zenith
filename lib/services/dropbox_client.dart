import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'backup_service.dart';
import 'cloud_backup_client.dart';
import 'network.dart';
import 'oauth_service.dart';

/// Minimal Dropbox API v2 client for backup files.
///
/// Every file lives in [folder]. With an "App folder" Dropbox app that is
/// `Apps/<app name>/Backups`; with full access it is `/Zenith Backups`.
class DropboxClient implements CloudBackupClient {
  DropboxClient(this._auth, {this.chunkSize = 1024 * 1024});

  final OAuthService _auth;
  static final _log = Logger('DropboxClient');

  static const folder = '/Zenith Backups';
  static const _api = 'https://api.dropboxapi.com/2';
  static const _content = 'https://content.dropboxapi.com/2';

  @override
  Future<CloudAccount> currentAccount() async {
    final res = await _rpc('users/get_current_account', null);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final name = json['name'] as Map<String, dynamic>?;
    return CloudAccount(
      name: name?['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// Size of each request body when uploading: small enough for the
  /// progress to move and for [uploadChunkTimeout] to suit slow networks.
  final int chunkSize;

  /// Uploads through an upload session rather than a single `files/upload`.
  ///
  /// When Dropbox rejects a request it answers right away and closes the
  /// connection; if the client is still sending a big body it only sees
  /// "connection reset", losing the actual error (and the 401 that would
  /// trigger a token refresh). The session is opened with an empty request,
  /// so any rejection comes back readable, and the data then goes up in
  /// chunks of [chunkSize], which also lifts the 150 MB single-request limit.
  @override
  Future<void> upload(
    String name,
    Uint8List bytes, {
    TransferProgress? onProgress,
  }) async {
    final start = await _contentCall('files/upload_session/start', {
      'close': false,
    }, Uint8List(0));
    final sessionId =
        (jsonDecode(start.body) as Map<String, dynamic>)['session_id']
            as String;

    var offset = 0;
    while (bytes.length - offset > chunkSize) {
      await _contentCall('files/upload_session/append_v2', {
        'cursor': {'session_id': sessionId, 'offset': offset},
        'close': false,
      }, Uint8List.sublistView(bytes, offset, offset + chunkSize));
      offset += chunkSize;
      onProgress?.call(offset / bytes.length);
    }

    await _contentCall('files/upload_session/finish', {
      'cursor': {'session_id': sessionId, 'offset': offset},
      'commit': {
        'path': '$folder/$name',
        'mode': 'add',
        'autorename': true,
        'mute': true,
      },
    }, Uint8List.sublistView(bytes, offset));
    onProgress?.call(1);
  }

  /// Backups in [folder], newest first.
  @override
  Future<List<RemoteBackup>> list() async {
    final entries = <Map<String, dynamic>>[];
    http.Response res;
    try {
      res = await _rpc('files/list_folder', {'path': folder, 'limit': 2000});
    } on _DropboxApiError catch (e) {
      // No backup has been uploaded yet.
      if (e.summary.startsWith('path/not_found')) return [];
      rethrow;
    }
    var json = jsonDecode(res.body) as Map<String, dynamic>;
    while (true) {
      entries.addAll((json['entries'] as List).cast<Map<String, dynamic>>());
      if (json['has_more'] != true) break;
      res = await _rpc('files/list_folder/continue', {
        'cursor': json['cursor'],
      });
      json = jsonDecode(res.body) as Map<String, dynamic>;
    }

    final backups = [
      for (final e in entries)
        if (e['.tag'] == 'file' &&
            BackupService.isBackupFileName(e['name'] as String))
          RemoteBackup(
            name: e['name'] as String,
            id: e['path_lower'] as String,
            size: (e['size'] as num?)?.toInt() ?? 0,
            createdAt:
                BackupService.timeFromFileName(e['name'] as String) ??
                DateTime.parse(e['server_modified'] as String).toLocal(),
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  @override
  Future<Uint8List> download(
    String path, {
    int? size,
    TransferProgress? onProgress,
  }) async {
    final url = Uri.parse('$_content/files/download');
    final http.StreamedResponse res;
    try {
      res = await _auth.stream(
        'POST',
        url,
        headers: {
          'Dropbox-API-Arg': _apiArg({'path': path}),
        },
      );
    } on OAuthException {
      throw _sessionExpired;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _check(await http.Response.fromStream(res), url);
    }
    return readDownload(
      res.stream,
      total: res.contentLength ?? size,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> delete(String path) async {
    await _rpc('files/delete_v2', {'path': path});
  }

  @override
  Future<void> prune({required int keep}) async {
    final backups = await list();
    for (final old in backups.skip(keep)) {
      await delete(old.id);
    }
  }

  @override
  Future<void> revoke() async {
    try {
      await _auth.post(Uri.parse('$_api/auth/token/revoke'));
    } catch (_) {}
  }

  /// A content endpoint call: arguments in the header, raw bytes as body.
  Future<http.Response> _contentCall(
    String endpoint,
    Map<String, Object?> args,
    Uint8List body,
  ) {
    return _call(
      Uri.parse('$_content/$endpoint'),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': _apiArg(args),
      },
      body: body,
      timeout: uploadChunkTimeout,
    );
  }

  Future<http.Response> _rpc(String endpoint, Map<String, Object?>? args) {
    return _call(
      Uri.parse('$_api/$endpoint'),
      // Endpoints without arguments want no body and no content type.
      headers: args == null ? null : {'Content-Type': 'application/json'},
      body: args == null ? null : jsonEncode(args),
    );
  }

  // The refresh token was rejected; OAuthService already logged out.
  static const _sessionExpired = CloudReauthRequired(
    'Your Dropbox session expired. Connect Dropbox again.',
  );

  Future<http.Response> _call(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = networkTimeout,
  }) async {
    final http.Response res;
    try {
      res = await _auth.post(
        url,
        headers: headers,
        body: body,
        timeout: timeout,
      );
    } on OAuthException {
      throw _sessionExpired;
    }
    return _check(res, url);
  }

  /// [res], when it is a success; otherwise the error it means.
  http.Response _check(http.Response res, Uri url) {
    if (res.statusCode >= 200 && res.statusCode < 300) return res;

    String summary = '';
    String? userMessage;
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      summary = json['error_summary'] as String? ?? '';
      final message = json['user_message'];
      if (message is Map) userMessage = message['text'] as String?;
    } catch (_) {
      summary = res.body;
    }
    // The Dropbox app registration lacks a permission. Dropbox reports it as
    // a 400 "other/..." with the explanation only in `user_message`, and
    // reconnecting can't fix it until the scope is enabled in the console.
    final scope = RegExp(
      r"required scope '([\w.]+)'",
    ).firstMatch(userMessage ?? '')?.group(1);
    if (scope != null) {
      throw BackupException(
        "Zenith's Dropbox app is missing the '$scope' permission. "
        'Enable it in the Dropbox App Console (Permissions tab), then '
        'disconnect and connect Dropbox again.',
      );
    }
    if (res.statusCode == 401) {
      if (summary.startsWith('missing_scope')) {
        throw const CloudReauthRequired(
          'Zenith needs new Dropbox permissions to store backups. '
          'Connect Dropbox again.',
        );
      }
      throw const CloudReauthRequired(
        'Dropbox access was revoked. Connect Dropbox again.',
      );
    }
    if (summary.startsWith('path/insufficient_space')) {
      throw const BackupException('Your Dropbox is full.');
    }
    if (res.statusCode == 429) {
      throw const BackupException(
        'Dropbox is rate limiting requests. Try again in a few minutes.',
      );
    }
    // `error_summary` alone can be as vague as "other/...", so keep the
    // endpoint and the raw body to make unexpected failures diagnosable.
    final endpoint = url.path.replaceFirst('/2/', '');
    _log.warning('Dropbox $endpoint failed (${res.statusCode}): ${res.body}');
    throw _DropboxApiError(
      res.statusCode,
      summary,
      endpoint,
      userMessage ?? res.body,
    );
  }

  /// `Dropbox-API-Arg` must be ASCII; escape anything else as \uXXXX.
  static String _apiArg(Map<String, Object?> args) {
    return jsonEncode(args).replaceAllMapped(
      RegExp(r'[^\x00-\x7F]'),
      (m) => '\\u${m[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}',
    );
  }
}

class _DropboxApiError extends BackupException {
  _DropboxApiError(this.status, this.summary, this.endpoint, String details)
    : super(
        'Dropbox error ($status) on $endpoint: '
        '${_details(summary, details)}',
      );
  final int status;
  final String summary;
  final String endpoint;

  /// The summary, or Dropbox's explanation (its `user_message`, else the
  /// raw body) when the summary says nothing useful.
  static String _details(String summary, String details) {
    final vague = summary.isEmpty || summary.startsWith('other/');
    final text = vague && details.trim().isNotEmpty ? details.trim() : summary;
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }
}
