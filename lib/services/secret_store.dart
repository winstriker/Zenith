import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where API keys and the like are kept: out of the preferences, the
/// database and every backup.
abstract class SecretStore {
  Future<String?> read(String key);

  /// Saves [value] under [key], or forgets it when [value] is null or blank.
  Future<void> write(String key, String? value);
}

/// The device's keystore.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty
        ? _storage.delete(key: key)
        : _storage.write(key: key, value: trimmed);
  }
}

/// Forgets everything when the app closes. For tests.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? values]) : values = {...?values};
  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      values.remove(key);
    } else {
      values[key] = trimmed;
    }
  }
}

final secretStoreProvider = Provider<SecretStore>((ref) {
  return const SecureSecretStore();
});
