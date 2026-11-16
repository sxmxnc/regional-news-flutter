import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_store.dart';

abstract final class SecureStoreKeys {
  static const String authToken = 'auth_token';

  static const String installationId = 'installation_id';

  static const String fcmDeviceToken = 'fcm_device_token';
}

final class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore(this._storage, Map<String, String> initial)
    : _cache = <String, String>{...initial};

  final FlutterSecureStorage _storage;
  final Map<String, String> _cache;

  static Future<SecureKeyValueStore> load() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    Map<String, String> all = const <String, String>{};
    try {
      all = await storage.readAll();
    } on Object catch (error) {
      developer.log(
        'Sichere Ablage nicht lesbar, Start ohne Sitzung: $error',
        name: 'SecureKeyValueStore',
      );
    }
    return SecureKeyValueStore(storage, all);
  }

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
    await _storage.delete(key: key);
  }
}

/// Wird beim Start überschrieben (`lib/app.dart`), wie [keyValueStoreProvider].
/// Ein Zugriff vor dem Laden ist ein Programmierfehler und soll auffallen.
final Provider<KeyValueStore> secureKeyValueStoreProvider =
    Provider<KeyValueStore>(
      (Ref ref) => throw StateError(
        'secureKeyValueStoreProvider muss beim Start überschrieben werden '
        '(siehe lib/app.dart).',
      ),
    );
