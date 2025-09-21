import 'package:shared_preferences/shared_preferences.dart';

/// Local database service using SharedPreferences for key-value storage.
class LocalDb {
  LocalDb._();
  
  /// Singleton instance of LocalDb.
  static final instance = LocalDb._();
  
  /// Initializes the local database.
  Future<void> init() async {}

  /// Stores a string value with the given key.
  /// 
  /// If [value] is null, removes the key from storage.
  Future<void> put(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  /// Retrieves a string value for the given key.
  /// 
  /// Returns null if the key doesn't exist.
  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
