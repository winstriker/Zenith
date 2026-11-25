import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/providers/backup_providers.dart';
import 'package:zenith/services/backup_service.dart';
import 'package:zenith/services/cloud_backup_client.dart';
import 'package:zenith/services/google_drive_client.dart';
import 'package:zenith/services/oauth_service.dart';

/// In-memory stand-in for the parts of the Drive v3 API the client uses.
class FakeDrive {
  /// id -> metadata (name, mimeType, parents, trashed, createdTime).
  final meta = <String, Map<String, dynamic>>{};
  final content = <String, Uint8List>{};
  final sessions = <String, (Map<String, dynamic>, int, BytesBuilder)>{};

  /// Data-carrying PUTs to upload sessions.
  int chunks = 0;
  String validToken = 'token-1';
  int refreshes = 0;
  String? revoked;
  bool quotaExceeded = false;
  var _ids = 0;

  late final client = MockClient(_handle);

  http.Response _json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response _error(int code, String reason) => _json({
    'error': {
      'code': code,
      'message': reason,
      'errors': [
        {'reason': reason, 'message': reason},
      ],
    },
  }, code);

  String _newId() => 'id${_ids++}';

  Iterable<String> _children(String parent) => meta.keys.where(
    (id) =>
        (meta[id]!['parents'] as List?)?.contains(parent) == true &&
        meta[id]!['trashed'] != true,
  );

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path;
    if (req.url.host == 'oauth2.googleapis.com') {
      if (path == '/revoke') {
        revoked = req.bodyFields['token'];
        return _json({});
      }
      expect(req.bodyFields['grant_type'], 'refresh_token');
      refreshes++;
      validToken = 'token-${refreshes + 1}';
      return _json({'access_token': validToken, 'expires_in': 3599});
    }
    if (req.headers['Authorization'] != 'Bearer $validToken') {
      return _error(401, 'authError');
    }

    // Upload session chunks.
    if (path.startsWith('/session/')) {
      expect(req.method, 'PUT');
      final id = path.split('/').last;
      final (metadata, total, data) = sessions[id]!;
      final range = RegExp(
        r'bytes (\d+)-(\d+)/(\d+)',
      ).firstMatch(req.headers['Content-Range']!)!;
      expect(int.parse(range.group(1)!), data.length);
      expect(int.parse(range.group(3)!), total);
      data.add(req.bodyBytes);
      chunks++;
      if (data.length < total) {
        return http.Response(
          '',
          308,
          headers: {'range': 'bytes=0-${data.length - 1}'},
        );
      }
      final fileId = _newId();
      meta[fileId] = {...metadata, 'createdTime': '2026-11-14T10:00:00Z'};
      content[fileId] = data.takeBytes();
      return _json({'id': fileId});
    }

    switch ((req.method, path)) {
      case ('POST', '/upload/drive/v3/files'):
        expect(req.url.queryParameters['uploadType'], 'resumable');
        if (quotaExceeded) return _error(403, 'storageQuotaExceeded');
        final metadata = jsonDecode(req.body) as Map<String, dynamic>;
        final parent = (metadata['parents'] as List).single as String;
        expect(meta[parent]?['mimeType'], 'application/vnd.google-apps.folder');
        final id = 's${sessions.length}';
        sessions[id] = (
          metadata,
          int.parse(req.headers['X-Upload-Content-Length']!),
          BytesBuilder(),
        );
        return http.Response(
          '',
          200,
          headers: {'location': 'https://www.googleapis.com/session/$id'},
        );
      case ('POST', '/drive/v3/files'):
        final id = _newId();
        meta[id] = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({'id': id});
      case ('GET', '/drive/v3/files'):
        final q = req.url.queryParameters['q']!;
        final inFolder = RegExp(r"^'(\w+)' in parents").firstMatch(q);
        if (inFolder != null) {
          return _json({
            'files': [
              for (final id in _children(inFolder.group(1)!))
                {
                  'id': id,
                  'name': meta[id]!['name'],
                  'size': '${content[id]?.length ?? 0}',
                  'createdTime': meta[id]!['createdTime'],
                },
            ],
          });
        }
        final name = RegExp("name = '([^']+)'").firstMatch(q)!.group(1);
        return _json({
          'files': [
            for (final e in meta.entries)
              if (e.value['name'] == name &&
                  e.value['mimeType'] == 'application/vnd.google-apps.folder' &&
                  e.value['trashed'] != true)
                {'id': e.key},
          ],
        });
      case ('GET', '/drive/v3/about'):
        return _json({
          'user': {
            'displayName': 'A Pilot',
            'emailAddress': 'pilot@example.com',
          },
        });
    }
    final file = RegExp(r'^/drive/v3/files/(\w+)$').firstMatch(path);
    if (file != null) {
      final id = file.group(1)!;
      if (!meta.containsKey(id)) return _error(404, 'notFound');
      if (req.method == 'DELETE') {
        meta.remove(id);
        content.remove(id);
        return http.Response('', 204);
      }
      if (req.method == 'GET' && req.url.queryParameters['alt'] == 'media') {
        return http.Response.bytes(content[id]!, 200);
      }
    }
    return http.Response('unknown endpoint ${req.method} $path', 404);
  }
}

void main() {
  late FakeDrive drive;
  late OAuthService auth;
  late GoogleDriveClient client;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'google_drive_access_token': 'token-1',
      'google_drive_refresh_token': 'refresh',
      'google_drive_expires_at': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    drive = FakeDrive();
    auth = OAuthService(
      'google_drive',
      'https://accounts.google.com/o/oauth2/v2/auth',
      'https://oauth2.googleapis.com/token',
      '123-abc.apps.googleusercontent.com',
      googleRedirectUri,
      'https://www.googleapis.com/auth/drive.file',
      httpClient: drive.client,
    );
    client = GoogleDriveClient(auth);
  });

  Uint8List bytes(int n) => Uint8List.fromList(List.filled(n, n % 256));

  test('upload, list, download and prune', () async {
    expect(await client.list(), isEmpty);

    for (var day = 1; day <= 4; day++) {
      final name = BackupService.fileNameFor(DateTime(2026, 11, day, 10));
      await client.upload(name, bytes(day * 10));
    }
    // One backup folder, created on the first upload.
    final folders = drive.meta.values.where(
      (m) => m['mimeType'] == 'application/vnd.google-apps.folder',
    );
    expect(folders.single['name'], GoogleDriveClient.folderName);

    var backups = await client.list();
    expect(backups, hasLength(4));
    expect(backups.first.createdAt, DateTime(2026, 11, 4, 10));
    expect(backups.first.size, 40);

    final received = <double>[];
    expect(
      await client.download(backups.first.id, onProgress: received.add),
      bytes(40),
    );
    expect(received.last, 1);

    await client.prune(keep: 2);
    backups = await client.list();
    expect(backups.map((b) => b.createdAt.day), [4, 3]);
  });

  test('uploads in chunks through a resumable session', () async {
    client = GoogleDriveClient(auth, chunkSize: 16);
    final data = Uint8List.fromList(List.generate(40, (i) => i));
    final sent = <double>[];
    await client.upload(
      'zenith_backup_20261114_100000.zip',
      data,
      onProgress: sent.add,
    );
    expect(drive.content.values.single, data);
    expect(sent, [16 / 40, 32 / 40, 1]);
    expect(drive.chunks, 3);
  });

  test('account info', () async {
    final account = await client.currentAccount();
    expect(account.email, 'pilot@example.com');
    expect(account.name, 'A Pilot');
  });

  test('refreshes an expired token and retries', () async {
    drive.validToken = 'something-else';
    await client.upload(BackupService.fileNameFor(DateTime(2026)), bytes(3));
    expect(drive.refreshes, 1);
    expect(drive.content, hasLength(1));
  });

  test('a full Drive is explained', () async {
    drive.quotaExceeded = true;
    await expectLater(
      client.upload('zenith_backup_20261114_100000.zip', bytes(1)),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          'Your Google Drive is full.',
        ),
      ),
    );
  });

  test('a rejected refresh token asks to reconnect', () async {
    final rejecting = OAuthService(
      'google_drive',
      'https://accounts.google.com/o/oauth2/v2/auth',
      'https://oauth2.googleapis.com/token',
      'id',
      'x:/y',
      'scope',
      httpClient: MockClient(
        (req) async => http.Response('{"error":"invalid_grant"}', 400),
      ),
    );
    FlutterSecureStorage.setMockInitialValues({
      'google_drive_refresh_token': 'refresh',
    });
    await expectLater(
      GoogleDriveClient(rejecting).list(),
      throwsA(isA<CloudReauthRequired>()),
    );
  });

  test('a sign-in server in trouble does not sign out', () async {
    for (final status in [429, 500, 503]) {
      final failing = OAuthService(
        'google_drive',
        'https://accounts.google.com/o/oauth2/v2/auth',
        'https://oauth2.googleapis.com/token',
        'id',
        'x:/y',
        'scope',
        httpClient: MockClient((req) async => http.Response('', status)),
      );
      FlutterSecureStorage.setMockInitialValues({
        'google_drive_refresh_token': 'refresh',
      });
      await expectLater(
        GoogleDriveClient(failing).list(),
        throwsA(
          isA<BackupException>().having(
            (e) => e,
            'kind',
            isNot(isA<CloudReauthRequired>()),
          ),
        ),
      );
      expect(await failing.isLoggedIn(), isTrue);
    }
  });

  test('revoke posts the refresh token', () async {
    await client.revoke();
    expect(drive.revoked, 'refresh');
  });

  test('the redirect URI matches callbacks', () {
    expect(
      auth.matchesCallback(
        Uri.parse('it.winstriker.zenith:/oauth2redirect?code=c&state=s'),
      ),
      isTrue,
    );
    expect(
      auth.matchesCallback(Uri.parse('zenithlogbook://dropbox?code=c')),
      isFalse,
    );
  });

  test('only the debug flavor on iOS has its own redirect', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final (platform, debugFlavor, scheme) in [
      (TargetPlatform.iOS, true, 'it.winstriker.zenithdebug'),
      (TargetPlatform.iOS, false, 'it.winstriker.zenith'),
      (TargetPlatform.android, true, 'it.winstriker.zenith'),
      (TargetPlatform.android, false, 'it.winstriker.zenith'),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        googleRedirectUriFor(debugFlavor: debugFlavor),
        '$scheme:/oauth2redirect',
      );
    }
  });
}
