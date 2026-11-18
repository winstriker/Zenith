import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show appBuildNumber;
import 'package:http/http.dart' as http;

import 'file_opener.dart';

/// The GitHub repository releases are published to, such as
/// `https://github.com/winstriker/Zenith`. Empty: this build can't update.
const updatesRepoUrl = String.fromEnvironment('UPDATES_REPO_URL');

/// A published release: its tag (`v1.2.0+42`) and the APK to install.
typedef AppRelease = ({String version, Uri apkUrl});

/// Finds and downloads new versions from the repository's GitHub releases.
///
/// Releases are tagged `v<name>+<build number>` by the release workflow; the
/// build number is Android's version code, so it alone tells which is newer.
class UpdateService {
  UpdateService({
    http.Client? client,
    this.repoUrl = updatesRepoUrl,
    int? currentBuild,
  }) : _client = client ?? http.Client(),
       currentBuild = currentBuild ?? int.tryParse(appBuildNumber ?? '') ?? 0;

  final http.Client _client;
  final String repoUrl;
  final int currentBuild;

  /// The latest release, when it is newer than this build.
  Future<AppRelease?> latestNewer() async {
    final path = Uri.tryParse(repoUrl)?.pathSegments ?? const [];
    if (path.length < 2) {
      throw const FormatException('Updates are not set up in this build');
    }
    final repo = '${path[0]}/${path[1].replaceFirst(RegExp(r'\.git$'), '')}';
    final response = await _client.get(
      Uri.https('api.github.com', '/repos/$repo/releases/latest'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub replied ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = json['tag_name'] as String;
    final build = int.tryParse(RegExp(r'\+(\d+)$').firstMatch(tag)?[1] ?? '');
    if (build == null || build <= currentBuild) return null;
    for (final asset in (json['assets'] as List).cast<Map<String, dynamic>>()) {
      if ((asset['name'] as String).endsWith('.apk')) {
        return (
          version: tag,
          apkUrl: Uri.parse(asset['browser_download_url'] as String),
        );
      }
    }
    throw FormatException('Release $tag has no APK');
  }

  /// Downloads [release]'s APK into the folder the installer can read from,
  /// reporting the fraction done (null when the size is unknown).
  Future<File> download(
    AppRelease release,
    void Function(double? fraction) onProgress,
  ) async {
    final dir = await FileOpener.exportsDirectory();
    final file = File('${dir.path}/zenith-update.apk');
    final response = await _client.send(http.Request('GET', release.apkUrl));
    if (response.statusCode != HttpStatus.ok) {
      await response.stream.drain<void>();
      throw HttpException('GitHub replied ${response.statusCode}');
    }
    final total = response.contentLength;
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(total == null || total <= 0 ? null : received / total);
      }
    } finally {
      await sink.close();
    }
    return file;
  }

  /// Hands [apk] to Android's package installer, which asks the user to
  /// confirm (and, the first time, to allow installs from Zenith).
  Future<void> install(File apk) => FileOpener.open(
    apk.path,
    mimeType: 'application/vnd.android.package-archive',
  );
}
