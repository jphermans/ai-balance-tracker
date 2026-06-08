# Provider Data Sync — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Sync provider configurations across iOS and macOS devices using Supabase as the cloud backend, with local-first hybrid storage so the app works offline.

**Architecture:** Local-first hybrid — read/write to local SharedPreferences immediately, sync to Supabase in background via Postgres Changes realtime subscriptions. Anonymous device-level auth with optional email linking for true cross-device identity. Last-write-wins conflict resolution with per-provider timestamps.

**Tech Stack:** Supabase (PostgreSQL + Realtime), supabase_flutter v2.x, shared_preferences (existing), Riverpod (existing)

**Why Supabase over Firebase:**
- **Free tier**: 500MB DB, 2GB bandwidth, 50k MAU — no credit card needed
- **PostgreSQL**: Relational schema fits our structured ProviderConfig model perfectly
- **Realtime**: Native Postgres Changes subscriptions — no polling, instant sync
- **Anonymous auth**: Device-level identity without forcing login
- **Open source**: Self-hostable if needed later; no vendor lock-in
- **macOS support**: `supabase_flutter` works on macOS without extra ceremony
- **Firebase downsides**: Requires Google Cloud billing setup even for free tier; NoSQL (Firestore) is harder to model relational data; `flutterfire configure` adds complex platform-specific configs; macOS support in FlutterFire is spotty

---

## Database Schema (Supabase PostgreSQL)

```sql
-- Table: provider_configs
CREATE TABLE provider_configs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id TEXT NOT NULL,                    -- e.g., "openai-abc123"
  type        TEXT NOT NULL,                    -- ProviderType enum name
  api_key     TEXT NOT NULL,                    -- encrypted or raw (Supabase Vault for production)
  org_id      TEXT,
  account_id  TEXT,
  custom_endpoint TEXT,
  enabled     BOOLEAN NOT NULL DEFAULT true,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, provider_id)                  -- one config per provider per user
);

-- Enable Realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE provider_configs;

-- RLS: users can only access their own configs
ALTER TABLE provider_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own configs"
  ON provider_configs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own configs"
  ON provider_configs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own configs"
  ON provider_configs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own configs"
  ON provider_configs FOR DELETE
  USING (auth.uid() = user_id);

-- Index for fast lookup
CREATE INDEX idx_provider_configs_user ON provider_configs(user_id);
```

---

## Tasks

### Phase 1: Supabase Project & Infrastructure

#### Task 1: Create Supabase project

**Objective:** Set up a Supabase project with the provider_configs table.

**Steps:**
1. Go to https://database.new/ and create a new Supabase project
   - Name: `ai-balance-tracker`
   - Region: nearest to user (e.g., `eu-west-1` for Belgium)
   - Database password: generate and save securely
2. Go to Project Settings → API and note:
   - Project URL
   - `anon` public key (publishable key)
3. Go to Authentication → Settings:
   - Enable "Allow anonymous sign-ins" (for device-level identity)
   - Under "Auth providers", disable Email (keep anonymous only for MVP; add Email later for cross-device linking)
4. Go to SQL Editor and run the schema from above (create table + RLS policies + realtime)
5. Go to Table Editor → provider_configs → enable Realtime (or verify ALTER PUBLICATION above)

**Verification:** Project shows in Supabase dashboard, table exists with RLS policies.

---

#### Task 2: Add supabase_flutter dependency

**Objective:** Add the Supabase Flutter SDK to the project.

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**

```yaml
dependencies:
  supabase_flutter: ^2.8.0
```

**Step 2: Run pub get**

```bash
cd /home/jphermans/projects/ai-balance-flutter && flutter pub get
```

**Verification:** `flutter pub get` succeeds, no version conflicts.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add supabase_flutter"
```

---

#### Task 3: Create Supabase config abstraction

**Objective:** Create a service that initializes Supabase and exposes the client.

**Files:**
- Create: `lib/services/supabase_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase initialization and client access.
class SupabaseService {
  static bool _initialized = false;

  /// Call once at app startup.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;

    // Listen to auth state for debugging
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Supabase] Auth event: ${data.event}');
    });
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Sign in anonymously — creates a persistent device identity.
  static Future<void> signInAnonymously() async {
    final session = client.auth.currentSession;
    if (session != null) return; // Already signed in
    await client.auth.signInAnonymously();
  }

  /// Current user ID, or null if not signed in.
  static String? get userId => client.auth.currentUser?.id;
}
```

**Step 2: Commit**

```bash
git add lib/services/supabase_service.dart
git commit -m "feat: add SupabaseService for init + anonymous auth"
```

---

### Phase 2: Database Integration

#### Task 4: Create SyncProviderConfig model

**Objective:** Extend ProviderConfig with sync metadata (updated_at timestamp for conflict resolution).

**Files:**
- Modify: `lib/models/provider_config.dart`

**Step 1: Add `updatedAt` field**

Add to `ProviderConfig`:
```dart
final DateTime? updatedAt; // Set by cloud on sync; null = local-only
```

Add to `fromJson`:
```dart
updatedAt: json['updated_at'] != null
    ? DateTime.parse(json['updated_at'] as String)
    : null,
```

Add to `toJson`:
```dart
if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
```

Add to `copyWith`:
```dart
DateTime? updatedAt,
```

**Step 2: Run analyze**

```bash
flutter analyze
```

**Step 3: Commit**

```bash
git add lib/models/provider_config.dart
git commit -m "feat: add updatedAt field to ProviderConfig for sync conflict resolution"
```

---

#### Task 5: Create SyncService (read/write to Supabase)

**Objective:** Service that reads/writes provider configs to Supabase.

**Files:**
- Create: `lib/services/sync_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_config.dart';
import 'supabase_service.dart';

/// Handles reading and writing provider configs to Supabase.
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

  /// Listen for realtime changes from Supabase.
  /// Returns a stream of changed provider configs.
  static Stream<List<ProviderConfig>> watchChanges() {
    final userId = SupabaseService.userId;
    if (userId == null) return Stream.value([]);

    return _db
        .from('provider_configs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows
            .map((row) => _fromRow(row as Map<String, dynamic>))
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
```

**Step 2: Run analyze**

```bash
flutter analyze
```

**Step 3: Commit**

```bash
git add lib/services/sync_service.dart
git commit -m "feat: add SyncService — CRUD + realtime sync to Supabase"
```

---

### Phase 3: Hybrid Storage (Local + Cloud)

#### Task 6: Create HybridStorageService

**Objective:** Service that writes to local storage AND Supabase, reads from local first, reconciles on startup.

**Files:**
- Create: `lib/services/hybrid_storage_service.dart`

```dart
import 'dart:async';
import 'secure_storage_service.dart';
import 'sync_service.dart';
import 'supabase_service.dart';
import '../models/provider_config.dart';

/// Local-first hybrid storage: write local → sync to cloud in background.
/// On startup: load local, then merge with cloud (last-write-wins).
class HybridStorageService {
  static StreamSubscription? _realtimeSub;

  /// Initialize: sign in, load providers, reconcile, start realtime.
  static Future<List<ProviderConfig>> initialize() async {
    // 1. Ensure signed in
    await SupabaseService.signInAnonymously();

    // 2. Load local data
    final localProviders = await SecureStorageService.loadProviders();

    // 3. Try loading cloud data
    try {
      final cloudProviders = await SyncService.fetchAll();
      final merged = _merge(localProviders, cloudProviders);

      // 4. Save merged back locally
      await SecureStorageService.saveProviders(merged);

      // 5. Push any local-only providers to cloud
      for (final p in merged) {
        await SyncService.upsert(p);
      }

      return merged;
    } catch (_) {
      // Cloud unavailable — just use local
      return localProviders;
    }
  }

  /// Save a provider — local first, then cloud in background.
  static Future<void> saveProvider(ProviderConfig config) async {
    // Local write (fast, always works)
    final updated = config.copyWith(updatedAt: DateTime.now().toUtc());
    await SecureStorageService.saveProvider(updated);

    // Cloud write (fire-and-forget)
    SyncService.upsert(updated).catchError((_) {});
  }

  /// Remove a provider — local first, then cloud.
  static Future<void> removeProvider(String providerId) async {
    await SecureStorageService.removeProvider(providerId);
    SyncService.remove(providerId).catchError((_) {});
  }

  /// Start listening for cloud changes and applying them locally.
  static void startRealtimeSync(
    void Function(List<ProviderConfig>) onProvidersChanged,
  ) {
    _realtimeSub?.cancel();
    _realtimeSub = SyncService.watchChanges().listen(
      (cloudProviders) async {
        if (cloudProviders.isEmpty) return;

        // Merge cloud → local (cloud wins on conflicts)
        final local = await SecureStorageService.loadProviders();
        final merged = _merge(local, cloudProviders, cloudWins: true);
        await SecureStorageService.saveProviders(merged);
        onProvidersChanged(merged);
      },
      onError: (_) { /* realtime unavailable, local still works */ },
    );
  }

  static void dispose() => _realtimeSub?.cancel();

  /// Merge local and cloud provider lists.
  /// When [cloudWins] is true and both have the same provider,
  /// the one with the newer updatedAt wins.
  static List<ProviderConfig> _merge(
    List<ProviderConfig> local,
    List<ProviderConfig> cloud, {
    bool cloudWins = false,
  }) {
    final map = <String, ProviderConfig>{};

    // Add local first
    for (final p in local) {
      map[p.id] = p;
    }

    // Overlay cloud
    for (final c in cloud) {
      final existing = map[c.id];
      if (existing == null) {
        map[c.id] = c;
      } else if (cloudWins) {
        // Cloud has priority in realtime push
        map[c.id] = c;
      } else {
        // On startup: last-write-wins
        final localTime = existing.updatedAt ?? DateTime(2000);
        final cloudTime = c.updatedAt ?? DateTime(2000);
        if (cloudTime.isAfter(localTime)) {
          map[c.id] = c;
        }
      }
    }

    return map.values.toList();
  }
}
```

**Step 2: Commit**

```bash
git add lib/services/hybrid_storage_service.dart
git commit -m "feat: add HybridStorageService — local-first with cloud sync + realtime merge"
```

---

### Phase 4: App Integration

#### Task 7: Initialize Supabase in main.dart

**Objective:** Call SupabaseService.initialize() + HybridStorageService in main.dart, replace direct SecureStorage calls.

**Files:**
- Modify: `lib/main.dart`

**Step 1: Update main()**

Replace the current `SecureStorageService.initialize()` + `FirstLaunchService.handleFirstLaunch()` block with:

```dart
import 'services/supabase_service.dart';
import 'services/hybrid_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (url/key from env or hardcoded for MVP)
  await SupabaseService.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Load providers (local + cloud merge)
  try {
    await HybridStorageService.initialize();
  } catch (_) {
    // App will work with local-only data
  }

  // Handle first-launch cleanup (uses SharedPreferences, not Keychain)
  await FirstLaunchService.handleFirstLaunch();

  runApp(const ProviderScope(child: AIBalanceApp()));
}
```

**Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire Supabase + hybrid storage into main()"
```

---

#### Task 8: Update AppState to use HybridStorage

**Objective:** Replace all `SecureStorageService` calls in app state management with `HybridStorageService`.

**Files:**
- Modify: `lib/state/app_state.dart`

**Step 1: Update provider state notifier**

Find all calls to `SecureStorageService.saveProviders()`, `loadProviders()`, `saveProvider()`, `removeProvider()` and replace with `HybridStorageService` equivalents.

Example:
```dart
// Before
await SecureStorageService.saveProviders(providers);

// After
await HybridStorageService.saveProviders(providers);
// Note: HybridStorageService.saveProviders doesn't exist yet
// We need to save each provider individually or batch
for (final p in providers) {
  await HybridStorageService.saveProvider(p);
}
```

**Step 2: Start realtime sync in app startup**

In the app's initialization (e.g., in `AIBalanceApp` initState or a Riverpod provider), call:
```dart
HybridStorageService.startRealtimeSync((providers) {
  ref.read(providerListProvider.notifier).state = providers;
});
```

**Step 3: Commit**

```bash
git add lib/state/app_state.dart
git commit -m "feat: switch app state to HybridStorageService"
```

---

### Phase 5: Cross-Device Identity (optional, Phase 2)

#### Task 9: Add email-based account linking

**Objective:** Allow users to link an email to their anonymous account for true cross-device sync.

**Files:**
- Create: `lib/screens/account_screen.dart`
- Modify: `lib/screens/settings_screen.dart`

**Steps:**
1. Add "Sign In" button in Settings screen
2. Create AccountScreen with email/password sign-up/sign-in
3. When user signs in with email, Supabase links it to the existing anonymous session
4. On other devices: sign in with same email → load same provider data

**This task is deferred** — anonymous auth covers single-device use case; email linking is for Phase 2 when true cross-device is needed.

---

### Phase 6: API Key Security

#### Task 10: Evaluate API key encryption for cloud storage

**Objective:** Decide whether to encrypt API keys before storing in Supabase.

**Tradeoffs:**
- **Unencrypted**: Simpler, but API keys visible in Supabase dashboard. Acceptable for personal use if RLS is properly configured.
- **Encrypted with Supabase Vault**: Secure, but adds complexity. Vault is a paid feature.
- **Client-side encryption**: Encrypt with a device-derived key before sending to Supabase. Makes cross-device sync harder (different devices have different keys).

**Recommendation for MVP:** Store raw API keys with strict RLS. The user is the only one who can access their own data. For production/App Store release, switch to Supabase Vault or client-side encryption.

---

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `lib/services/supabase_service.dart` | Create | Supabase init + anonymous auth |
| `lib/services/sync_service.dart` | Create | CRUD + realtime to Supabase |
| `lib/services/hybrid_storage_service.dart` | Create | Local-first with cloud merge |
| `lib/models/provider_config.dart` | Modify | Add `updatedAt` field |
| `lib/main.dart` | Modify | Wire Supabase init |
| `lib/state/app_state.dart` | Modify | Switch to HybridStorage |
| `pubspec.yaml` | Modify | Add `supabase_flutter` |

---

## Verification Steps

1. **Unit test**: `HybridStorageService._merge()` correctly merges local + cloud with last-write-wins
2. **Integration test**: Add a provider on macOS → it appears on iOS (and vice versa)
3. **Offline test**: Disable network → app still works with local data → re-enable → syncs
4. **Conflict test**: Modify the same provider on both devices offline → on reconnect, last-write-wins

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| API keys in cloud | RLS restricts to authenticated user; consider Vault for production |
| Supabase free tier limits | 500MB DB is massive for config JSON; 50k MAU is more than enough for personal use |
| Realtime subscription drops | App falls back to local-only; reconnects on next launch |
| Anonymous auth lost on app reinstall | Email linking (Task 9) solves this; for now, re-add providers after reinstall |

---

## Open Questions

1. **Supabase project region**: Which region is closest? (`eu-west-1` for Belgium)
2. **API key encryption**: Acceptable to store raw keys with RLS for MVP? (Recommend: yes for now)
3. **Email auth**: Defer to Phase 2 or include now? (Recommend: defer — anonymous covers the user's use case)
4. **Supabase URL/key storage**: Use `--dart-define` at build time, or hardcode? (Recommend: `--dart-define` for CI, hardcoded placeholder for local dev)
