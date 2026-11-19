import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/person_photo_store.dart';
import 'navigation_provider.dart';

/// The picture the user put behind a tab's header; null for the default
/// gradient. Only its file name is kept in the preferences.
class HeaderImageNotifier extends Notifier<File?> {
  HeaderImageNotifier(this.tab);
  final MainTab tab;

  String get _key => 'header_image_${tab.name}';

  HeaderImageStore get _store => ref.read(headerImageStoreProvider);

  @override
  File? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name == null) return;
    final file = File('${(await _store.directory).path}/$name');
    if (file.existsSync()) state = file;
  }

  /// Copies [picked] into the store and shows it, dropping the previous one.
  Future<void> set(File picked) async {
    final name = await _store.save(picked);
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_key);
    await prefs.setString(_key, name);
    state = File('${(await _store.directory).path}/$name');
    await _store.delete(previous);
  }

  /// Goes back to the default gradient.
  Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_key);
    await prefs.remove(_key);
    state = null;
    await _store.delete(previous);
  }
}

final headerImageProvider =
    NotifierProvider.family<HeaderImageNotifier, File?, MainTab>(
      HeaderImageNotifier.new,
    );
