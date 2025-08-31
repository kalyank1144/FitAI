import 'package:shared_preferences/shared_preferences.dart';

class LocalDb {
  LocalDb._();
  static final instance = LocalDb._();
  Future<void> init() async {}

  Future<void> put(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}