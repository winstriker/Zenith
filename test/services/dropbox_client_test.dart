import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/services/backup_service.dart';
import 'package:zenith/services/cloud_backup_client.dart';
import 'package:zenith/services/dropbox_client.dart';
import 'package:zenith/services/oauth_service.dart';

/// In-memory stand-in for the parts of the Dropbox API the client uses,
/// strict about the request shapes Dropbox itself enforces.
class FakeDropbox {
  final files = <String, Uint8List>{};
  final sessions = <String, BytesBuilder>{};

  /// Data-carrying session requests (append_v2 and finish).
  int appends = 0;
  String validToken = 'token-1';
  int refreshes = 0;
  bool missingScope = false;

  /// The app registration itself lacks the write scope: Dropbox answers 400
  /// "other/..." and explains only in `user_message`.
  bool appLacksWriteScope = false;

  late final client = MockClient(_handle);

  http.Response _json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path;
    if (path == '/oauth2/token') {
      expect(req.bodyFields['grant_type'], 'refresh_token');
      expect(req.bodyFields['refresh_token'], 'refresh');
      refreshes++;
      validToken = 'token-${refreshes + 1}';
      return _json({'access_token': validToken, 'expires_in': 14400});
    }

    if (req.headers['Authorization'] != 'Bearer $validToken') {
      return _json({
        'error_summary': 'expired_access_token/',
        'error': {'.tag': 'expired_access_token'},
      }, 401);
    }
    if (missingScope) {
      return _json({
        'error_summary': 'missing_scope/',
        'error': {
          '.tag': 'missing_scope',
          'required_scope': 'files.content.write',
        },
      }, 401);
    }

    if (appLacksWriteScope && path.contains('upload')) {
      return _json({
        'error': {'.tag': 'other'},
        'error_summary': 'other/...',
        'user_message': {
          'locale': 'en',
          'text':
              'Error in call to API function "files/upload_session/start": '
              'Your app (ID: 1) is not permitted to access this endpoint '
              "because it does not have the required scope "
              "'files.content.write'. The owner of the app can enable the "
              'scope for the app using the Permissions tab on the App '
              'Console.',
        },
      }, 400);
    }

    Map<String, dynamic> arg() =>
        jsonDecode(req.headers['Dropbox-API-Arg']!) as Map<String, dynamic>;
    Map<String, dynamic> body() => jsonDecode(req.body) as Map<String, dynamic>;

    switch (path) {
      case '/2/files/upload_session/start':
      case '/2/files/upload_session/append_v2':
      case '/2/files/upload_session/finish':
        expect(req.url.host, 'content.dropboxapi.com');
        expect(req.headers['Content-Type'], 'application/octet-stream');
        // Header must be pure ASCII.
        expect(
          req.headers['Dropbox-API-Arg']!.codeUnits.every((c) => c < 128),
          isTrue,
        );
        if (path.endsWith('/start')) {
          // Opened empty, so a rejection can't be lost mid-body.
          expect(req.bodyBytes, isEmpty);
          final id = 'session-${sessions.length}';
          sessions[id] = BytesBuilder();
          return _json({'session_id': id});
        }
        final cursor = arg()['cursor'] as Map<String, dynamic>;
        final session = sessions[cursor['session_id']]!;
        if (cursor['offset'] != session.length) {
          return _json({
            'error_summary': 'incorrect_offset/..',
            'error': {'.tag': 'incorrect_offset'},
          }, 409);
        }
        session.add(req.bodyBytes);
        appends++;
        if (path.endsWith('/append_v2')) return _json(null);
        final p = (arg()['commit']['path'] as String).toLowerCase();
        files[p] = session.takeBytes();
        return _json({'name': p.split('/').last, 'path_lower': p});
      case '/2/files/list_folder':
        expect(req.headers['Content-Type'], startsWith('application/json'));
        final folder = (body()['path'] as String).toLowerCase();
        final inFolder = files.keys.where((k) => k.startsWith('$folder/'));
        if (inFolder.isEmpty) {
          return _json({
            'error_summary': 'path/not_found/..',
            'error': {'.tag': 'path'},
          }, 409);
        }
        return _json({
          'entries': [
            for (final k in inFolder)
              {
                '.tag': 'file',
                'name': k.split('/').last,
                'path_lower': k,
                'size': files[k]!.length,
                'server_modified': '2026-11-14T10:00:00Z',
              },
            {'.tag': 'folder', 'name': 'other', 'path_lower': '$folder/other'},
          ],
          'has_more': false,
          'cursor': 'c',
        });
      case '/2/files/download':
        expect(req.url.host, 'content.dropboxapi.com');
        final data = files[arg()['path']];
        if (data == null) {
          return _json({'error_summary': 'path/not_found/'}, 409);
        }
        return http.Response.bytes(data, 200);
      case '/2/files/delete_v2':
        files.remove(body()['path']);
        return _json({'metadata': <String, Object>{}});
      case '/2/users/get_current_account':
        // Dropbox rejects a content type on argument-less endpoints.
        expect(req.headers.containsKey('Content-Type'), isFalse);
        expect(req.bodyBytes, isEmpty);
        return _json({
          'email': 'pilot@example.com',
          'name': {'display_name': 'A Pilot'},
        });
    }
    return http.Response('unknown endpoint $path', 404);
  }
}

void main() {
  late FakeDropbox dropbox;
  late OAuthService auth;
  late DropboxClient client;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'dropbox_access_token': 'token-1',
      'dropbox_refresh_token': 'refresh',
      'dropbox_expires_at': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    dropbox = FakeDropbox();
    auth = OAuthService(
      'dropbox',
      'https://www.dropbox.com/oauth2/authorize',
      'https://api.dropboxapi.com/oauth2/token',
      'key',
      'zenithlogbook://dropbox',
      'files.content.write',
      authorizationParams: const {'token_access_type': 'offline'},
      httpClient: dropbox.client,
    );
    client = DropboxClient(auth);
  });

  Uint8List bytes(int n) => Uint8List.fromList(List.filled(n, n % 256));

  test('upload, list, download and prune', () async {
    expect(await client.list(), isEmpty);

    for (var day = 1; day <= 4; day++) {
      final name = BackupService.fileNameFor(DateTime(2026, 11, day, 10));
      await client.upload(name, bytes(day * 10));
    }
    var backups = await client.list();
    expect(backups, hasLength(4));
    expect(backups.first.createdAt, DateTime(2026, 11, 4, 10));
    expect(backups.first.size, 40);

    final downloaded = await client.download(backups.first.id);
    expect(downloaded, bytes(40));

    await client.prune(keep: 2);
    backups = await client.list();
    expect(backups.map((b) => b.createdAt.day), [4, 3]);
  });

  test('uploads in chunks through an upload session', () async {
    client = DropboxClient(auth, chunkSize: 16);
    final data = Uint8List.fromList(List.generate(40, (i) => i));
    await client.upload('zenith_backup_20261114_100000.zip', data);
    expect(dropbox.files.values.single, data);
    // 16 + 16 appended, the last 8 sent with finish.
    expect(dropbox.appends, 3);

    // A file that fits in one chunk goes up with finish alone.
    dropbox.appends = 0;
    await client.upload('zenith_backup_20261114_110000.zip', bytes(16));
    expect(dropbox.appends, 1);
  });

  test('account info', () async {
    final account = await client.currentAccount();
    expect(account.email, 'pilot@example.com');
    expect(account.name, 'A Pilot');
  });

  test('refreshes an expired token and retries', () async {
    dropbox.validToken = 'something-else';
    await client.upload(BackupService.fileNameFor(DateTime(2026)), bytes(3));
    expect(dropbox.refreshes, 1);
    expect(dropbox.files, hasLength(1));
  });

  test('missing permissions ask to reconnect', () async {
    dropbox.missingScope = true;
    await expectLater(
      client.upload('x.json.gz', bytes(1)),
      throwsA(isA<CloudReauthRequired>()),
    );
  });

  test('a scope missing from the Dropbox app is explained', () async {
    dropbox.appLacksWriteScope = true;
    await expectLater(
      client.upload('zenith_backup_20261114_100000.zip', bytes(1)),
      throwsA(
        isA<BackupException>()
            .having((e) => e, 'type', isNot(isA<CloudReauthRequired>()))
            .having(
              (e) => e.message,
              'message',
              allOf(contains("'files.content.write'"), contains('App Console')),
            ),
      ),
    );
  });
}
