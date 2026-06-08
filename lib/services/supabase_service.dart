import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase initialization and client access.
/// Call [initialize] once at app startup, then use [client].
class SupabaseService {
  static bool _initialized = false;

  /// Call once at app startup with your Supabase project URL and anon key.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;

    // Log auth state changes for debugging
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Supabase] Auth event: ${data.event}');
    });
  }

  /// The Supabase client instance. Access after [initialize].
  static SupabaseClient get client {
    assert(_initialized, 'SupabaseService.initialize() must be called first');
    return Supabase.instance.client;
  }

  /// Sign in anonymously — creates a persistent device identity.
  /// Safe to call multiple times; returns immediately if already signed in.
  static Future<void> signInAnonymously() async {
    final session = client.auth.currentSession;
    if (session != null) return;
    await client.auth.signInAnonymously();
  }

  /// Current authenticated user ID, or null if not signed in.
  static String? get userId => client.auth.currentUser?.id;
}
