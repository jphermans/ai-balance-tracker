import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase initialization and client access.
/// Call [initialize] once at app startup, then use [client].
///
/// IMPORTANT: Supabase.instance is a global singleton. Calling dispose()
/// and re-initializing mid-app is not supported by the SDK (it closes
/// internal stream controllers that can't be reopened). To switch
/// credentials, save the new config and restart the app.
class SupabaseService {
  static bool _initialized = false;
  static StreamSubscription? _authSub;

  /// Whether Supabase is currently initialized.
  static bool get isInitialized => _initialized;

  /// Call once at app startup with your Supabase project URL and anon key.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;

    // Cancel any previous subscription before creating a new one
    _authSub?.cancel();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
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
    if (session != null) {
      debugPrint('[Supabase] already signed in as ${session.user.id}');
      return;
    }
    debugPrint('[Supabase] signing in anonymously...');
    await client.auth.signInAnonymously();
    debugPrint('[Supabase] signed in as ${client.auth.currentUser?.id}');
  }

  /// Current authenticated user ID, or null if not signed in.
  static String? get userId => client.auth.currentUser?.id;
}
