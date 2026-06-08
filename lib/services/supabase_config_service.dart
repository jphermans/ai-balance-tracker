import 'package:shared_preferences/shared_preferences.dart';

/// Persists Supabase URL and anon key to SharedPreferences so users
/// can configure cloud sync from within the app (no build flags needed).
class SupabaseConfigService {
  static const _keyUrl = 'supabase_url';
  static const _keyAnonKey = 'supabase_anon_key';

  /// Save Supabase connection details.
  static Future<void> saveConfig({
    required String url,
    required String anonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url);
    await prefs.setString(_keyAnonKey, anonKey);
  }

  /// Load saved Supabase connection details. Returns (url, anonKey)
  /// or (null, null) if nothing has been saved.
  static Future<(String?, String?)> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyUrl);
    final key = prefs.getString(_keyAnonKey);
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      return (null, null);
    }
    return (url, key);
  }

  /// Remove stored Supabase config. Next launch will try dart-define
  /// or run in local-only mode.
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyAnonKey);
  }

  /// Whether a Supabase config has been saved.
  static Future<bool> hasConfig() async {
    final (url, _) = await loadConfig();
    return url != null;
  }
}
