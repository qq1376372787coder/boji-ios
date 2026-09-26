import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  final Map<String, String> _memory = <String, String>{};

  Future<String> read({required String key}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key) ?? _memory[key] ?? '';
    } catch (_) {
      return _memory[key] ?? '';
    }
  }

  Future<void> write({required String key, required String value}) async {
    _memory[key] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Keep the in-memory value when platform storage is unavailable.
    }
  }

  Future<void> delete({required String key}) async {
    _memory.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Keep the deletion successful in memory.
    }
  }
}
