/// Storage boundary for persistence.
///
/// The core depends only on this interface so it stays platform independent;
/// the Flutter layer provides a `shared_preferences` implementation and tests
/// use [InMemoryKeyValueStore].
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<void> remove(String key);
}

/// Non-persistent store used by tests and as a safe default.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? initial])
    : _values = {...?initial};

  final Map<String, Object> _values;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
