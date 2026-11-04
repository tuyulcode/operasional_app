import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InputDraft {
  InputDraft._();

  static const String _draftKey = 'input_draft';

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      await clear();
    }
    return null;
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
