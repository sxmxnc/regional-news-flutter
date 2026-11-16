import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStore {
  String? getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

/// Namen der abgelegten Werte. An einer Stelle, damit kein Tippfehler eine
/// gespeicherte Einstellung unsichtbar macht.
abstract final class StoreKeys {
  static const String language = 'language';

  static const String textScale = 'text_scale';

  static const String notificationsEnabled = 'notifications_enabled';
}

/// Umsetzung über `shared_preferences`.
final class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStore> load() async {
    return SharedPreferencesStore(await SharedPreferences.getInstance());
  }

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

final Provider<KeyValueStore> keyValueStoreProvider = Provider<KeyValueStore>(
  (Ref ref) => throw StateError(
    'keyValueStoreProvider muss beim Start überschrieben werden '
    '(siehe lib/app.dart).',
  ),
);
