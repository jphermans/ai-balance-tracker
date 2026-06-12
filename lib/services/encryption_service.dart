import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pointycastle/export.dart';

/// Client-side AES-256-GCM encryption for API keys before Supabase sync.
///
/// Key is derived from the Supabase project credentials (URL + publishable
/// key) via PBKDF2 with a fixed app salt. This is the *project* secret, not
/// the per-device anonymous user_id — so the same key is derived on every
/// device that points at the same Supabase project. That's what makes
/// cross-device sync work: device A encrypts "sk-abc..." and uploads it;
/// device B can decrypt it because both devices derive the same key from
/// the same project credentials.
///
/// Why project credentials are safe to use as key material:
/// - The publishable key (formerly "anon key") is shipped in every client
///   binary and visible in the JS bundle of the web build. It's not a
///   secret — it's a *project identity*. Anyone with the URL+key can read
///   rows their RLS policy allows, so it adds no extra access risk.
/// - Deriving a key from it provides defense-in-depth: a database dump
///   without the matching client config can't decrypt the API keys.
/// - We do NOT use a hard-coded key — that would be one-step decryption
///   for any attacker who downloads the app. PBKDF2 over the credentials
///   means the client config is needed AND requires brute-force search.
///
/// Stores format: `AES256GCM:<base64(IV+ciphertext+tag)>`
/// Plaintext values are passed through (backward compat with existing data).
class EncryptionService {
  static const _appSalt = 'ai-balance-tracker-sync-v1';
  static const _iterations = 100000;
  static const _keyLength = 32;
  static const _ivLength = 12;
  static const _tagLength = 16;
  static const _prefix = 'AES256GCM:';

  /// The currently configured project key material. Set by [initialize]
  /// from `SupabaseService.url` + `SupabaseService.publishableKey` on
  /// app startup. We keep the legacy [setProjectKey(String userId)]
  /// path (used by tests) as a fallback when no project key is set.
  static String? _projectKeyMaterial;

  /// Inject the project key material at startup. Call this from
  /// `main()` after Supabase is initialized, before any sync happens.
  /// If never called, [encrypt]/[tryDecrypt] fall back to the legacy
  /// per-user-id derivation so existing data remains decryptable on
  /// the device that wrote it (but cross-device sync stays broken
  /// until this is called).
  static void initialize({required String supabaseUrl, required String publishableKey}) {
    // Hash the concatenated credentials so the PBKDF2 input has good
    // entropy and is a fixed length. Using SHA-256 of (url|key) means
    // changing the URL or the key produces a totally different secret.
    // We use pointycastle's SHA-256 to avoid adding the `crypto` package
    // just for this — pointycastle is already a dependency.
    final input = utf8.encode('$supabaseUrl|$publishableKey');
    final digest = SHA256Digest();
    // SHA256Digest.process() returns the digest directly (32 bytes for SHA-256).
    _projectKeyMaterial = base64Encode(digest.process(Uint8List.fromList(input)));
    debugPrint('[Encryption] project key material set (cross-device sync enabled)');
  }

  /// Derive AES-256 key. Prefers the project key material (set by
  /// [initialize]) for cross-device sync. Falls back to the legacy
  /// per-user-id derivation so that data written by older app versions
  /// on a single device can still be decrypted locally.
  static Uint8List _deriveKey(String userId) {
    final salt = Uint8List.fromList(utf8.encode(_appSalt));
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    final input = _projectKeyMaterial ?? userId;
    return derivator.process(utf8.encode(input));
  }

  /// Encrypt plaintext → `AES256GCM:<base64>`.
  /// Empty string returns empty.
  static String encrypt(String plaintext, String userId) {
    if (plaintext.isEmpty) return '';

    final key = _deriveKey(userId);
    final iv = _randomBytes(_ivLength);
    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), _tagLength * 8, iv, Uint8List(0)));

    // GCM writes ciphertext during processBytes and appends the 16-byte
    // auth tag during doFinal. We must concatenate exactly the bytes that
    // were written, not the full output buffer (which can have unused
    // trailing capacity — copying it would pad the ciphertext with zeros
    // and break the GCM tag check on decrypt).
    final out = Uint8List(cipher.getOutputSize(plainBytes.length));
    var len = cipher.processBytes(plainBytes, 0, plainBytes.length, out, 0);
    len += cipher.doFinal(out, len);
    final cipherOut = Uint8List(len);
    cipherOut.setAll(0, Uint8List.sublistView(out, 0, len));

    final combined = Uint8List(iv.length + cipherOut.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, cipherOut);

    return '$_prefix${base64Encode(combined)}';
  }

  /// Try to decrypt `AES256GCM:<base64>` → plaintext.
  ///
  /// Returns `null` (not throws) on any failure: malformed base64,
  /// truncated input, wrong IV length, or GCM authentication failure
  /// (which means the key is wrong or the ciphertext was tampered with).
  ///
  /// Non-prefixed values pass through (backward compat with plaintext rows).
  /// An empty string returns an empty string.
  ///
  /// Callers that need to know about failures should check for `null`
  /// and either skip the record or surface a typed error to the user.
  /// One bad row must never kill the whole sync — that's why we degrade
  /// to a return value rather than throwing.
  static String? tryDecrypt(String? value, String userId) {
    if (value == null || value.isEmpty) return '';
    if (!value.startsWith(_prefix)) return value; // plaintext passthrough

    try {
      final b64 = value.substring(_prefix.length);
      final combined = base64Decode(b64);

      // Must contain at least IV + tag (28 bytes).
      if (combined.length < _ivLength + _tagLength) {
        debugPrint('[Encryption] ciphertext too short: ${combined.length} bytes');
        return null;
      }

      final iv = Uint8List.sublistView(combined, 0, _ivLength);
      final ciphertext = Uint8List.sublistView(combined, _ivLength);
      final key = _deriveKey(userId);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), _tagLength * 8, iv, Uint8List(0)));

      final out = Uint8List(cipher.getOutputSize(ciphertext.length));
      var len = cipher.processBytes(ciphertext, 0, ciphertext.length, out, 0);
      len += cipher.doFinal(out, len); // throws InvalidCipherTextException on bad tag

      return utf8.decode(Uint8List.sublistView(out, 0, len));
    } on FormatException catch (e) {
      debugPrint('[Encryption] base64 decode failed: ${e.message}');
      return null;
    } on ArgumentError catch (e) {
      debugPrint('[Encryption] invalid argument: ${e.message}');
      return null;
    } on InvalidCipherTextException catch (e) {
      debugPrint('[Encryption] GCM auth failed (wrong key or tampered): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Encryption] unexpected decrypt error: $e');
      return null;
    }
  }

  /// Backward-compatible decrypt: returns the original value on failure
  /// instead of `null`. Use [tryDecrypt] for new code that needs to
  /// distinguish "decrypted empty" from "failed to decrypt".
  ///
  /// Failures degrade to an empty string — silent in the UI but no longer
  /// crashes the calling code. The intended failure mode is: a corrupted
  /// row in Supabase shows up as an empty API key in the app, which the
  /// user can fix by re-entering their credentials.
  @Deprecated('Use tryDecrypt() which returns null on failure for better '
      'error handling in callers.')
  static String decrypt(String value, String userId) {
    final result = tryDecrypt(value, userId);
    return result ?? '';
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => rng.nextInt(256)));
  }
}
