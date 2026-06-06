import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/provider_config.dart';

/// Secure storage backed by iOS Keychain / Android EncryptedSharedPreferences.
/// Never stores credentials in plain text or SharedPreferences.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _providersKey = 'ai_balance_providers';

  static Future<void> initialize() async {
    // Trigger keychain access early; no-op if already initialized
    await _storage.read(key: '_init_check');
  }

  /// Save all provider configurations securely.
  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final json = providers.map((p) => p.toJson()).toList();
    await _storage.write(key: _providersKey, value: jsonEncode(json));
  }

  /// Load all provider configurations.
  static Future<List<ProviderConfig>> loadProviders() async {
    final json = await _storage.read(key: _providersKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ProviderConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save a single provider config.
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

  /// Remove a provider config.
  static Future<void> removeProvider(String providerId) async {
    final providers = await loadProviders();
    providers.removeWhere((p) => p.id == providerId);
    await saveProviders(providers);
  }

  /// Delete all stored credentials.
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
