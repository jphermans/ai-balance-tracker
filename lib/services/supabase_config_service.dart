import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Supabase URL and anon key so users can configure cloud sync
/// from within the app (no build flags needed).
///
/// Storage split:
/// - URL → SharedPreferences (not secret, can be read by any process)
/// - Anon key → flutter_secure_storage on iOS/Android (Keychain/EncryptedSharedPreferences)
///                or SharedPreferences on web/macOS (unsigned CI builds can't use
///                Keychain on macOS, and web has no secure storage option).
///
/// The anon key is technically a *public* credential (Supabase RLS protects data)
/// but storing it in secure storage when possible reduces its visibility to other
/// apps on the device and to backup-extraction tools.
class SupabaseConfigService {
  static const _keyUrl = 'supabase_url';
  static const _keyAnonKey = 'supabase_anon_key';
  static const _secureAnonKey = 'supabase_anon_key_secure';
  static final _secure = const FlutterSecureStorage();

  static bool get _useSecure =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android);

  /// Whether the anon key is stored in [FlutterSecureStorage] on this
  /// platform. Exposed publicly for tests and for the Settings UI to
  /// surface a "securely stored" badge.
  static bool get usesSecureStorage => _useSecure;

  /// Save Supabase connection details.
  static Future<void> saveConfig({
    required String url,
    required String anonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url);

    if (_useSecure) {
      await _secure.write(key: _secureAnonKey, value: anonKey);
      // Best-effort: clear any old SharedPreferences copy so the key isn't
      // sitting in plaintext after the user upgrades the app.
      await prefs.remove(_keyAnonKey);
    } else {
      await prefs.setString(_keyAnonKey, anonKey);
    }
  }

  /// Load saved Supabase connection details. Returns (url, anonKey)
  /// or (null, null) if nothing has been saved.
  ///
  /// Reads from secure storage first (where supported), falling back to
  /// SharedPreferences for the migration case where a user upgrades from a
  /// previous version that stored the key in plaintext.
  static Future<(String?, String?)> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyUrl);
    if (url == null || url.isEmpty) return (null, null);

    String? key;
    if (_useSecure) {
      key = await _secure.read(key: _secureAnonKey);
    }
    // Fallback / non-secure platforms: read the SharedPreferences copy.
    key ??= prefs.getString(_keyAnonKey);

    if (key == null || key.isEmpty) return (url, null);
    return (url, key);
  }

  /// Remove stored Supabase config. Next launch will try dart-define
  /// or run in local-only mode.
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyAnonKey);
    if (_useSecure) {
      await _secure.delete(key: _secureAnonKey);
    }
  }

  /// Whether a Supabase config has been saved.
  static Future<bool> hasConfig() async {
    final (url, _) = await loadConfig();
    return url != null;
  }
}
