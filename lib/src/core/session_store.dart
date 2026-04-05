import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'kalpix_session.dart';

/// Persists session data to shared preferences.
class SessionStore {
  static const String _sessionKey = 'kalpix_session';

  Future<void> save(KalpixSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toMap()));
  }

  Future<KalpixSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return KalpixSession.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
