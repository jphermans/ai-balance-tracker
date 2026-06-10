import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_config.dart';
import 'supabase_service.dart';
import 'encryption_service.dart';

/// Reads and writes provider configs to Supabase.
/// API keys are AES-256-GCM encrypted client-side before storage.
class SyncService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch all provider configs from Supabase (cross-device, no user filter).
  static Future<List<ProviderConfig>> fetchAll() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    final response = await _db
        .from('provider_configs')
        .select()
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => _fromRow(row as Map<String, dynamic>, userId))
        .toList();
  }

  /// Upsert a single provider config to Supabase.
  /// API key is encrypted before storage.
  static Future<void> upsert(ProviderConfig config) async {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    debugPrint('[Sync] upsert ${config.id}: type=${config.type.name}');
    await _db.from('provider_configs').upsert({
      'provider_id': config.id,
      'type': config.type.name,
      'api_key': EncryptionService.encrypt(config.apiKey, userId),
      'org_id': config.orgId,
      'account_id': config.accountId,
      'custom_endpoint': config.customEndpoint,
      'enabled': config.enabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'provider_id');
  }

  /// Delete a provider config from Supabase.
  static Future<void> remove(String providerId) async {
    await _db
        .from('provider_configs')
        .delete()
        .eq('provider_id', providerId);
  }

  /// Listen for realtime changes via Postgres Changes.
  /// Returns a stream of current provider configs whenever they change.
  static Stream<List<ProviderConfig>> watchChanges() {
    final userId = SupabaseService.userId;
    if (userId == null) return const Stream.empty();

    return _db
        .from('provider_configs')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((row) => _fromRow(row, userId))
            .toList());
  }

  static ProviderConfig _fromRow(Map<String, dynamic> row, String userId) {
    return ProviderConfig(
      id: row['provider_id'] as String,
      type: ProviderType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => ProviderType.openai,
      ),
      apiKey: EncryptionService.decrypt(row['api_key'] as String, userId),
      orgId: row['org_id'] as String?,
      accountId: row['account_id'] as String?,
      customEndpoint: row['custom_endpoint'] as String?,
      enabled: row['enabled'] as bool? ?? true,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}
