import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_config.dart';

/// Secure/durable storage for provider configs and credentials.
/// Uses iOS Keychain on iOS, SharedPreferences on macOS/web/other platforms
/// (because Keychain blocks unsigned macOS apps, unavailable on web).
class SecureStorageService {
  static const _providersKey = 'ai_balance_providers';
  static final _secure = FlutterSecureStorage();

  static bool get _useSecure =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android);

  static Future<void> initialize() async {
    if (_useSecure) {
      await _secure.read(key: '_init_check');
    }
  }

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // --- Read/Write abstraction ---

  static Future<void> _write(String key, String value) async {
    if (_useSecure) {
      await _secure.write(key: key, value: value);
    } else {
      final p = await _prefs;
      await p.setString(key, value);
    }
  }

  static Future<String?> _read(String key) async {
    if (_useSecure) {
      return await _secure.read(key: key);
    } else {
      final p = await _prefs;
      return p.getString(key);
    }
  }

  static Future<void> _delete(String key) async {
    if (_useSecure) {
      await _secure.delete(key: key);
    } else {
      final p = await _prefs;
      await p.remove(key);
    }
  }

  static Future<void> deleteAll() async {
    if (_useSecure) {
      await _secure.deleteAll();
    } else {
      final p = await _prefs;
      await p.remove(_providersKey);
    }
  }

  // --- Public API ---

  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final json = providers.map((p) => p.toJson()).toList();
    await _write(_providersKey, jsonEncode(json));
  }

  static Future<List<ProviderConfig>> loadProviders() async {
    final json = await _read(_providersKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ProviderConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveProvider(ProviderConfig config) async {
    final providers = await loadProviders();
    final index = providers.indexWhere((p) => p.id == config.id);
    if (index >= 0) {
      providers[index] = config;
    } else {
      providers.add(config);
    }
    await saveProviders(providers);
  }

  static Future<void> removeProvider(String providerId) async {
    final providers = await loadProviders();
    providers.removeWhere((p) => p.id == providerId);
    await saveProviders(providers);
  }
}
