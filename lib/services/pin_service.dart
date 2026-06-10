import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

/// Manages the optional PIN lock.
/// Uses iOS/macOS Keychain or SharedPreferences.
class PinService {
  static const _pinKey = 'app_pin_hash';
  static final _secure = FlutterSecureStorage();

  static bool get _useSecure =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android);

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<String?> _read() async {
    if (_useSecure) {
      return await _secure.read(key: _pinKey);
    } else {
      final p = await _prefs;
      return p.getString(_pinKey);
    }
  }

  static Future<void> _write(String value) async {
    if (_useSecure) {
      await _secure.write(key: _pinKey, value: value);
    } else {
      final p = await _prefs;
      await p.setString(_pinKey, value);
    }
  }

  /// Check if a PIN is currently set.
  static Future<bool> hasPin() async {
    final value = await _read();
    return value != null && value.isNotEmpty;
  }

  /// Store a new PIN (PBKDF2 hashed with random salt).
  static Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = _deriveKey(pin, salt);
    await _write('${base64Encode(salt)}:${base64Encode(hash)}');
  }

  /// Verify a PIN against the stored hash.
  static Future<bool> verifyPin(String pin) async {
    final stored = await _read();
    if (stored == null) return false;

    // Backward compat: old DJB2 format (no colon, 8 hex chars)
    if (!stored.contains(':')) {
      // Re-hash with old method to verify, then upgrade
      if (stored == _legacyHash(pin)) {
        await setPin(pin); // upgrade to PBKDF2
        return true;
      }
      return false;
    }

    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = base64Decode(parts[0]);
    final expectedHash = base64Decode(parts[1]);
    final actualHash = _deriveKey(pin, salt);
    return _constantTimeEquals(expectedHash, actualHash);
  }

  /// Remove the PIN lock.
  static Future<void> removePin() async {
    if (_useSecure) {
      await _secure.delete(key: _pinKey);
    } else {
      final p = await _prefs;
      await p.remove(_pinKey);
    }
  }

  /// Derive a 32-byte key using PBKDF2-HMAC-SHA256.
  static Uint8List _deriveKey(String password, Uint8List salt) {
    const iterations = 100000;
    const keyLength = 32;
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return derivator.process(utf8.encode(password));
  }

  /// Cryptographically secure random bytes.
  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => rng.nextInt(256)));
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Legacy DJB2 hash for backward compatibility during upgrade.
  static String _legacyHash(String input) {
    const salt = 0x5A3F9C1E;
    var hash = salt;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
