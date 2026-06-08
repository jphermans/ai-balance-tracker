import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the optional PIN lock.
/// Uses iOS Keychain on iOS, SharedPreferences on macOS
/// (Keychain blocks unsigned macOS apps).
class PinService {
  static const _pinKey = 'app_pin_hash';
  static final _secure = FlutterSecureStorage();

  static bool get _useSecure =>
      Platform.isIOS || Platform.isAndroid;

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

  /// Store a new PIN (hashed for security).
  static Future<void> setPin(String pin) async {
    await _write(_hash(pin));
  }

  /// Verify a PIN against the stored hash.
  static Future<bool> verifyPin(String pin) async {
    final stored = await _read();
    if (stored == null) return false;
    return stored == _hash(pin);
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

  /// Simple hash to avoid storing the PIN in plaintext.
  static String _hash(String input) {
    const salt = 0x5A3F9C1E;
    var hash = salt;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
