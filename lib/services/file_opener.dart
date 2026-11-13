import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Opens app-owned files in the system's default viewer.
///
/// On Android files must live under [exportsDirectory] so they can be served
/// through the app's FileProvider; no storage permission is required.
class FileOpener {
  FileOpener._();

  static const _channel = MethodChannel('zenith/file_opener');

  /// `filesDir/exports` — the only directory exposed by the FileProvider.
  static Future<Directory> exportsDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/exports').create(recursive: true);
  }

  /// Throws a [PlatformException] (e.g. `NO_APP`, `NOT_FOUND`) on failure.
  static Future<void> open(String path, {required String mimeType}) async {
    await _channel.invokeMethod<bool>('open', {
      'path': path,
      'mimeType': mimeType,
    });
  }
}
