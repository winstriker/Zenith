import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores pictures as files in `<app support>/<folder>/`.
/// The database only keeps the file name, so the folder can move.
class PhotoStore {
  PhotoStore(this._root, this.folder);
  final Future<Directory> Function() _root;
  final String folder;

  Future<Directory> get directory async {
    final dir = Directory('${(await _root()).path}/$folder');
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

/// Profile pictures of people, in `<app support>/people_photos/`.
class PersonPhotoStore extends PhotoStore {
  PersonPhotoStore(Future<Directory> Function() root)
    : super(root, 'people_photos');
}

/// Aircraft photos the user picked themselves, in
/// `<app support>/aircraft_photos/`. Photos found online are not stored.
class AircraftPhotoStore extends PhotoStore {
  AircraftPhotoStore(Future<Directory> Function() root)
    : super(root, 'aircraft_photos');
}

final personPhotoStoreProvider = Provider<PersonPhotoStore>((ref) {
  return PersonPhotoStore(getApplicationSupportDirectory);
});

/// Resolved photo folder, for building [File]s synchronously in widgets.
final personPhotoDirectoryProvider = FutureProvider<Directory>((ref) {
  return ref.watch(personPhotoStoreProvider).directory;
});

final aircraftPhotoStoreProvider = Provider<AircraftPhotoStore>((ref) {
  return AircraftPhotoStore(getApplicationSupportDirectory);
});

/// Resolved aircraft photo folder, for building [File]s synchronously in
/// widgets.
final aircraftPhotoDirectoryProvider = FutureProvider<Directory>((ref) {
  return ref.watch(aircraftPhotoStoreProvider).directory;
});
