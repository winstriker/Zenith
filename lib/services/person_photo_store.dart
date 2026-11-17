import 'dart:io';
import 'dart:typed_data';

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

/// Signatures laid over the remarks of a flight in the exported logbook, in
/// `<app support>/signatures/`: drawn in the app, uploaded, or photographed
/// off the paper logbook.
class SignatureStore extends PhotoStore {
  SignatureStore(Future<Directory> Function() root) : super(root, 'signatures');

  /// Content of the stored file [name], or null when it is missing.
  Future<Uint8List?> read(String name) async {
    final file = File('${(await directory).path}/$name');
    return file.existsSync() ? file.readAsBytes() : null;
  }
}

/// Aircraft photos the user picked themselves, in
/// `<app support>/aircraft_photos/`. Photos found online are not stored.
class AircraftPhotoStore extends PhotoStore {
  AircraftPhotoStore(Future<Directory> Function() root)
    : super(root, 'aircraft_photos');
}

/// The picture behind the home page header, in `<app support>/home_header/`.
class HomeHeaderImageStore extends PhotoStore {
  HomeHeaderImageStore(Future<Directory> Function() root)
    : super(root, 'home_header');
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

final signatureStoreProvider = Provider<SignatureStore>((ref) {
  return SignatureStore(getApplicationSupportDirectory);
});

/// Resolved signature folder, for building [File]s synchronously in widgets.
final signatureDirectoryProvider = FutureProvider<Directory>((ref) {
  return ref.watch(signatureStoreProvider).directory;
});

final homeHeaderImageStoreProvider = Provider<HomeHeaderImageStore>((ref) {
  return HomeHeaderImageStore(getApplicationSupportDirectory);
});
