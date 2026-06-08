import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_config.dart';
import 'supabase_service.dart';

/// Reads and writes provider configs to Supabase.
class SyncService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch all provider configs for the current user from Supabase.
  static Future<List<ProviderConfig>> fetchAll() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    final response = await _db
        .from('provider_configs')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Upsert a single provider config to Supabase.
  static Future<void> upsert(ProviderConfig config) async {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    await _db.from('provider_configs').upsert({
      'user_id': userId,
      'provider_id': config.id,
      'type': config.type.name,
      'api_key': config.apiKey,
      'org_id': config.orgId,
      'account_id': config.accountId,
      'custom_endpoint': config.customEndpoint,
      'enabled': config.enabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id, provider_id');
  }

  /// Delete a provider config from Supabase.
  static Future<void> remove(String providerId) async {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    await _db
        .from('provider_configs')
        .delete()
        .eq('user_id', userId)
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
        .eq('user_id', userId)
        .map((rows) => rows
            .map((row) => _fromRow(row))
            .toList());
  }

  static ProviderConfig _fromRow(Map<String, dynamic> row) {
    return ProviderConfig(
      id: row['provider_id'] as String,
      type: ProviderType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => ProviderType.openai,
      ),
      apiKey: row['api_key'] as String,
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
