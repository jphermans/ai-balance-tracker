import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/supabase_config_service.dart';
import 'services/supabase_service.dart';
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
