import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores profile pictures as files in `<app support>/people_photos/`.
/// The database only keeps the file name, so the folder can move.
class PersonPhotoStore {
  PersonPhotoStore(this._root);
  final Future<Directory> Function() _root;

  Future<Directory> get directory async {
    final dir = Directory('${(await _root()).path}/people_photos');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [source] into the store under a fresh name and returns that name.
  /// A fresh name per change keeps Flutter's image cache from showing the old
  /// picture.
  Future<String> save(File source) async {
    final dot = source.path.lastIndexOf('.');
    final ext = dot < 0 ? '.jpg' : source.path.substring(dot);
    final name = '${const Uuid().v4()}$ext';
    await source.copy('${(await directory).path}/$name');
    return name;
  }

  Future<void> delete(String? name) async {
    if (name == null) return;
    final file = File('${(await directory).path}/$name');
    if (file.existsSync()) await file.delete();
  }
}

final personPhotoStoreProvider = Provider<PersonPhotoStore>((ref) {
  return PersonPhotoStore(getApplicationSupportDirectory);
});

/// Resolved photo folder, for building [File]s synchronously in widgets.
final personPhotoDirectoryProvider = FutureProvider<Directory>((ref) {
  return ref.watch(personPhotoStoreProvider).directory;
});
