import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/services/update_service.dart';

UpdateService _service(
  String tag, {
  List<String> assets = const ['zenith.apk'],
}) => UpdateService(
  repoUrl: 'https://github.com/winstriker/Zenith.git',
  currentBuild: 10,
  client: MockClient((request) async {
    expect(request.url.path, '/repos/winstriker/Zenith/releases/latest');
    return http.Response(
      jsonEncode({
        'tag_name': tag,
        'body': '- Fixed things\n',
        'assets': [
          for (final name in assets)
            {'name': name, 'browser_download_url': 'https://dl/$name'},
        ],
      }),
      200,
    );
  }),
);

void main() {
  test('a release with a higher build number is newer', () async {
    final release = await _service(
      'v1.0.0+11',
      assets: ['notes.txt', 'zenith.apk'],
    ).latestNewer();
    expect(release?.version, 'v1.0.0+11');
    expect(release?.notes, '- Fixed things');
    expect(release?.apkUrl, Uri.parse('https://dl/zenith.apk'));
  });

  test('the same, older or unnumbered builds are not', () async {
    for (final tag in ['v1.0.0+10', 'v2.0.0+9', 'v2.0.0']) {
      expect(await _service(tag).latestNewer(), isNull, reason: tag);
    }
  });

  test('a newer release without an APK is an error', () {
    expect(
      _service('v1.0.0+11', assets: []).latestNewer(),
      throwsFormatException,
    );
  });

  test('no repository set up is an error', () {
    expect(
      UpdateService(repoUrl: 'https://github.com/').latestNewer(),
      throwsFormatException,
    );
  });
}
