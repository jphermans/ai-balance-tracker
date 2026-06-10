import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Client-side AES-256-GCM encryption for API keys before Supabase sync.
///
/// Key is derived from Supabase user ID via PBKDF2 with a fixed app salt.
/// Stores format: `AES256GCM:<base64(IV+ciphertext+tag)>`
/// Plaintext values are passed through (backward compat with existing data).
class EncryptionService {
  static const _appSalt = 'ai-balance-tracker-sync-v1';
  static const _iterations = 100000;
  static const _keyLength = 32;
  static const _ivLength = 12;
  static const _tagLength = 16;
  static const _prefix = 'AES256GCM:';

  /// Derive AES-256 key from user ID.
  static Uint8List _deriveKey(String userId) {
    final salt = Uint8List.fromList(utf8.encode(_appSalt));
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    return derivator.process(utf8.encode(userId));
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

    final out = Uint8List(cipher.getOutputSize(plainBytes.length));
    final len = cipher.processBytes(plainBytes, 0, plainBytes.length, out, 0);
    cipher.doFinal(out, len);

    final combined = Uint8List(iv.length + out.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, out);

    return '$_prefix${base64Encode(combined)}';
  }

  /// Decrypt `AES256GCM:<base64>` → plaintext.
  /// Non-prefixed values pass through (backward compat).
  static String decrypt(String value, String userId) {
    if (value.isEmpty) return '';
    if (!value.startsWith(_prefix)) return value; // plaintext passthrough

    final b64 = value.substring(_prefix.length);
    final combined = base64Decode(b64);

    final iv = Uint8List.sublistView(combined, 0, _ivLength);
    final ciphertext = Uint8List.sublistView(combined, _ivLength);
    final key = _deriveKey(userId);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), _tagLength * 8, iv, Uint8List(0)));

    final out = Uint8List(cipher.getOutputSize(ciphertext.length));
    final len = cipher.processBytes(ciphertext, 0, ciphertext.length, out, 0);
    cipher.doFinal(out, len);

    return utf8.decode(Uint8List.sublistView(out, 0, len));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => rng.nextInt(256)));
  }
}
