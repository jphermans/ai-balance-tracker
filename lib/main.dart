import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/supabase_config_service.dart';
import 'services/supabase_service.dart';
import 'services/encryption_service.dart';
import 'services/hybrid_storage_service.dart';
import 'services/first_launch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Try saved user config first (from Settings screen)
  final (savedUrl, savedKey) = await SupabaseConfigService.loadConfig();

  // 2. Fall back to --dart-define build flags
  final supabaseUrl = (savedUrl != null && savedUrl.isNotEmpty)
      ? savedUrl
      : const String.fromEnvironment('SUPABASE_URL');
  final supabaseKey = (savedKey != null && savedKey.isNotEmpty)
      ? savedKey
      : const String.fromEnvironment('SUPABASE_ANON_KEY');

  // 3. Initialize Supabase if we have credentials
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await SupabaseService.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      // Hand the project credentials to the encryption service BEFORE
      // any sync runs. The encryption key is derived from these (not
      // from the per-device anonymous user_id), which is what makes
      // cross-device sync work — every device pointing at the same
      // Supabase project derives the same key and can decrypt each
      // other's API keys. If we skip this call, EncryptionService
      // falls back to the legacy per-user-id derivation, which works
      // locally but breaks cross-device sync.
      EncryptionService.initialize(
        supabaseUrl: supabaseUrl,
        publishableKey: supabaseKey,
      );

      // Load providers (local + cloud merge)
      await HybridStorageService.initialize().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      // Cloud unavailable — app works fine with local-only data
    }
  }

  // Handle first-launch cleanup after app deletion
  await FirstLaunchService.handleFirstLaunch();

  runApp(const ProviderScope(child: AIBalanceApp()));
}
