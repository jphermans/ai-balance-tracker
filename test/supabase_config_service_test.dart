import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_balance_tracker/services/supabase_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // defaultTargetPlatform defaults to Android in unit tests, which would
    // route anon-key storage through FlutterSecureStorage. The Linux test
    // runner has no Keychain implementation, so force Linux for tests.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('SupabaseConfigService (issue #43 fix #3)', () {
    test('saveConfig then loadConfig round-trips URL and key', () async {
      await SupabaseConfigService.saveConfig(
        url: 'https://abc.supabase.co',
        anonKey: 'eyJhbG...test',
      );
      final (url, key) = await SupabaseConfigService.loadConfig();
      expect(url, 'https://abc.supabase.co');
      // On non-iOS/Android (test runs on Linux), the key falls back to
      // SharedPreferences — assert that the value is preserved either way.
      if (SupabaseConfigService.usesSecureStorage) {
        // iOS/Android: secure storage backed — the value must be there.
        expect(key, isNotNull);
        expect(key, isNotEmpty);
      } else {
        // Linux/macOS/web: SharedPreferences fallback.
        expect(key, 'eyJhbG...test');
      }
    });

    test('loadConfig with nothing saved returns (null, null)', () async {
      final (url, key) = await SupabaseConfigService.loadConfig();
      expect(url, isNull);
      expect(key, isNull);
    });

    test('loadConfig with empty URL returns (null, null)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', '');
      final (url, key) = await SupabaseConfigService.loadConfig();
      expect(url, isNull);
      expect(key, isNull);
    });

    test('hasConfig reflects save state', () async {
      expect(await SupabaseConfigService.hasConfig(), isFalse);
      await SupabaseConfigService.saveConfig(
        url: 'https://abc.supabase.co',
        anonKey: 'k',
      );
      expect(await SupabaseConfigService.hasConfig(), isTrue);
    });

    test('clearConfig wipes both URL and key', () async {
      await SupabaseConfigService.saveConfig(
        url: 'https://abc.supabase.co',
        anonKey: 'k',
      );
      await SupabaseConfigService.clearConfig();
      expect(await SupabaseConfigService.hasConfig(), isFalse);
      final (url, key) = await SupabaseConfigService.loadConfig();
      expect(url, isNull);
      expect(key, isNull);
    });

    test('upgrade path: legacy SharedPrefs key is read on non-secure',
        () async {
      // Simulate a user upgrading from a previous version that stored
      // the key in SharedPreferences plaintext.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', 'https://abc.supabase.co');
      await prefs.setString('supabase_anon_key', 'legacy-plaintext-key');

      if (!SupabaseConfigService.usesSecureStorage) {
        // Non-secure platforms (Linux/macOS/web) should still find the key.
        final (url, key) = await SupabaseConfigService.loadConfig();
        expect(url, 'https://abc.supabase.co');
        expect(key, 'legacy-plaintext-key');
      }
      // On secure-storage platforms, the legacy SharedPrefs value is
      // intentionally ignored — the user must re-enter the key once.
    });
  });
}
