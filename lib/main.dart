import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/supabase_service.dart';
import 'services/hybrid_storage_service.dart';
import 'services/first_launch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for cloud sync.
  // Pass URL and key via --dart-define; app works offline without them.
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

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
