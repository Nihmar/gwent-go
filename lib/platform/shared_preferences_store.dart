import 'package:shared_preferences/shared_preferences.dart';

import '../core/persistence/key_value_store.dart';

/// [KeyValueStore] backed by `shared_preferences`.
///
/// This is the only place that knows about the persistence plugin, keeping the
/// core and the presentation layer platform independent.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  @override
  Future<String?> getString(String key) async => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async => _preferences.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<int?> getInt(String key) async => _preferences.getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
