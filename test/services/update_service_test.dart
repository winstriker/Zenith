import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/services/update_service.dart';

UpdateService _service(
  String tag, {
  List<String> assets = const ['zenith-universal.apk'],
  String? abi,
}) => UpdateService(
  repoUrl: 'https://github.com/winstriker/Zenith.git',
  currentBuild: 10,
  abi: abi,
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
      assets: ['notes.txt', 'zenith-universal.apk'],
    ).latestNewer();
    expect(release?.version, 'v1.0.0+11');
    expect(release?.notes, '- Fixed things');
    expect(release?.apkUrl, Uri.parse('https://dl/zenith-universal.apk'));
  });

  test('a pre-release version name updates a numbered one', () async {
    final release = await _service(
      'v1.0.0-beta-1+11',
      assets: [
        'zenith-1.0.0-beta-1+11-universal.apk',
        'zenith-1.0.0-beta-1+11-arm64-v8a.apk',
      ],
      abi: 'arm64-v8a',
    ).latestNewer();
    expect(release?.version, 'v1.0.0-beta-1+11');
    expect(
      release?.apkUrl,
      Uri.parse('https://dl/zenith-1.0.0-beta-1+11-arm64-v8a.apk'),
    );
  });

  test('the same, older or unnumbered builds are not', () async {
    for (final tag in [
      'v1.0.0+10',
      'v2.0.0+9',
      'v2.0.0',
      'v1.0.0-beta-1+10',
      'v1.0.0-beta-1',
    ]) {
      expect(await _service(tag).latestNewer(), isNull, reason: tag);
    }
  });

  test(
    'the APK for the architecture is preferred over the universal',
    () async {
      const abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
      final assets = [
        for (final name in [...abis, 'universal']) 'zenith-1.0.0+11-$name.apk',
      ];
      for (final (abi, expected) in [
        for (final abi in abis) (abi, abi),
        ('riscv64', 'universal'),
      ]) {
        final release = await _service(
          'v1.0.0+11',
          assets: assets,
          abi: abi,
        ).latestNewer();
        expect(
          release?.apkUrl,
          Uri.parse('https://dl/zenith-1.0.0+11-$expected.apk'),
        );
      }
    },
  );

  test('an APK for another architecture is not picked', () {
    expect(
      _service(
        'v1.0.0+11',
        assets: ['zenith-x86_64.apk'],
        abi: 'arm64-v8a',
      ).latestNewer(),
      throwsFormatException,
    );
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
