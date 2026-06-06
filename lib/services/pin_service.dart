import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the optional PIN lock using secure storage (iOS Keychain).
class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_pin_hash';

  /// Check if a PIN is currently set.
  static Future<bool> hasPin() async {
    final value = await _storage.read(key: _pinKey);
    return value != null && value.isNotEmpty;
  }

  /// Store a new PIN (hashed for security).
  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: _hash(pin));
  }

  /// Verify a PIN against the stored hash.
  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  /// Remove the PIN lock.
  static Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }

  /// Simple hash to avoid storing the PIN in plaintext.
  static String _hash(String input) {
    // XOR-based obfuscation with a fixed salt — not cryptographic,
    // but prevents casual plaintext reading from Keychain dump.
    const salt = 0x5A3F9C1E;
    var hash = salt;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
