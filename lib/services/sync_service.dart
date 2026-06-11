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

    final out = <ProviderConfig>[];
    for (final row in (response as List<dynamic>)) {
      final config = _fromRow(row as Map<String, dynamic>, userId);
      if (config != null) out.add(config);
    }
    return out;
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
        .map((rows) {
      final out = <ProviderConfig>[];
      for (final row in rows) {
        final config = _fromRow(row, userId);
        if (config != null) out.add(config);
      }
      return out;
    });
  }

  /// Build a [ProviderConfig] from a Supabase row, or `null` if the row
  /// can't be decrypted. We never throw from here — one bad row must not
  /// kill the whole sync. The caller ([fetchAll], [watchChanges]) filters
  /// out nulls and logs the skip via [debugPrint].
  static ProviderConfig? _fromRow(Map<String, dynamic> row, String userId) {
    // tryDecrypt returns null on any failure: malformed base64, wrong IV
    // length, GCM authentication tag mismatch (wrong key or tampered
    // ciphertext), or unexpected exceptions inside the cipher. See
    // issue #43 for the original bug — before this fix, a single bad
    // row propagated up through `fetchAll` and left the user with an
    // empty provider list and no diagnostic.
    final decrypted = EncryptionService.tryDecrypt(
      row['api_key'] as String?,
      userId,
    );
    if (decrypted == null) {
      debugPrint(
          '[Sync] skipping row ${row['provider_id']}: failed to decrypt api_key');
      return null;
    }
    return ProviderConfig(
      id: row['provider_id'] as String,
      type: ProviderType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => ProviderType.openai,
      ),
      apiKey: decrypted,
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
