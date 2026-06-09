import 'dart:async';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'sync_service.dart';
import 'supabase_service.dart';
import '../models/provider_config.dart';

/// Local-first hybrid storage: writes go to local storage immediately,
/// then sync to Supabase in background. On startup, merges local + cloud
/// with last-write-wins conflict resolution.
class HybridStorageService {
  static StreamSubscription? _realtimeSub;

  /// Initialize: sign in, load local, merge with cloud, start realtime.
  /// Returns the merged provider list.
  static Future<List<ProviderConfig>> initialize() async {
    // 1. Ensure signed in anonymously
    await SupabaseService.signInAnonymously();
    debugPrint('[Hybrid] signed in, userId=${SupabaseService.userId}');

    // 2. Load local data (always works, even offline)
    final localProviders = await SecureStorageService.loadProviders();
    debugPrint('[Hybrid] local providers: ${localProviders.length}');

    // 3. Try loading cloud data and merge
    try {
      final cloudProviders = await SyncService.fetchAll();
      debugPrint('[Hybrid] cloud providers: ${cloudProviders.length}');
      final merged = _merge(localProviders, cloudProviders);

      // 4. Save merged result locally
      await SecureStorageService.saveProviders(merged);

      // 5. Push any local-only or newer-local providers to cloud
      for (final p in merged) {
        debugPrint('[Hybrid] upserting ${p.type.name}');
        await SyncService.upsert(p);
      }

      debugPrint('[Hybrid] done — merged=${merged.length}');
      return merged;
    } catch (e) {
      debugPrint('[Hybrid] cloud error: $e');
      // Push local providers to cloud anyway so new device gets them
      for (final p in localProviders) {
        try {
          await SyncService.upsert(p.copyWith(updatedAt: DateTime.now().toUtc()));
        } catch (_) {}
      }
      return localProviders;
    }
  }

  /// Load providers from local storage (fast, no network).
  static Future<List<ProviderConfig>> loadProviders() async {
    return await SecureStorageService.loadProviders();
  }

  /// Save a provider: write local first, sync to cloud in background.
  static Future<void> saveProvider(ProviderConfig config) async {
    final updated = config.copyWith(updatedAt: DateTime.now().toUtc());
    await SecureStorageService.saveProvider(updated);
    // Fire-and-forget cloud sync
    SyncService.upsert(updated).catchError((_) {});
  }

  /// Remove a provider: delete from local, then cloud.
  static Future<void> removeProvider(String providerId) async {
    await SecureStorageService.removeProvider(providerId);
    SyncService.remove(providerId).catchError((_) {});
  }

  /// Delete all providers from local storage.
  static Future<void> deleteAll() async {
    await SecureStorageService.deleteAll();
  }

  /// Batch save all providers to local + cloud.
  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    await SecureStorageService.saveProviders(providers);
    // Sync to cloud in background
    for (final p in providers) {
      SyncService.upsert(p).catchError((_) {});
    }
  }

  /// Start listening for realtime cloud changes and applying them locally.
  static void startRealtimeSync(
    void Function(List<ProviderConfig>) onProvidersChanged,
  ) {
    _realtimeSub?.cancel();
    _realtimeSub = SyncService.watchChanges().listen(
      (cloudProviders) async {
        if (cloudProviders.isEmpty) return;
        final local = await SecureStorageService.loadProviders();
        final merged = _merge(local, cloudProviders, cloudWins: true);
        await SecureStorageService.saveProviders(merged);
        onProvidersChanged(merged);
      },
      onError: (_) {/* realtime unavailable — local still works */},
    );
  }

  /// Stop realtime subscription.
  static void dispose() => _realtimeSub?.cancel();

  /// Merge local and cloud provider lists.
  /// [cloudWins]: when true, cloud is the authoritative full-state snapshot
  /// (used for realtime pushes from other devices). Local-only entries not
  /// in cloud are removed (deletions) but local-only entries are preserved
  /// (offline additions). When false, last-write-wins by comparing
  /// [updatedAt] timestamps (used for startup merge).
  static List<ProviderConfig> _merge(
    List<ProviderConfig> local,
    List<ProviderConfig> cloud, {
    bool cloudWins = false,
  }) {
    final map = <String, ProviderConfig>{};

    if (cloudWins) {
      // Cloud is authoritative — deletions are respected.
      // Local-only entries are NOT preserved; they may be stale ghosts
      // from the pre-fix era (different user_id per device).
      // Offline-created entries are pushed to cloud at startup
      // (initialize step 5) before realtime subscription begins.
      for (final c in cloud) {
        map[c.id] = c;
      }
    } else {
      // Startup merge: local-first, cloud overlay with last-write-wins.
      for (final p in local) {
        map[p.id] = p;
      }
      for (final c in cloud) {
        final existing = map[c.id];
        if (existing == null) {
          map[c.id] = c;
        } else {
          final localTime = existing.updatedAt ?? DateTime(2000);
          final cloudTime = c.updatedAt ?? DateTime(2000);
          if (cloudTime.isAfter(localTime)) {
            map[c.id] = c;
          }
        }
      }
    }

    return map.values.toList();
  }
}
