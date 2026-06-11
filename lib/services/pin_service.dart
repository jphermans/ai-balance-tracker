import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

/// Result of a [PinService.verifyPin] attempt.
enum PinVerifyResult {
  /// PIN matched, access granted.
  success,
  /// PIN was wrong, but the user can retry (possibly after a delay).
  wrong,
  /// Account is currently locked out. [PinService.lockoutRemaining]
  /// tells the caller how long.
  locked,
}

/// Manages the optional PIN lock with brute-force protection.
///
/// Security model:
/// - PIN is stored as a PBKDF2-HMAC-SHA256 hash with a per-install random salt
/// - Failed attempts are persisted and rate-limited with exponential backoff
/// - After 20 failed attempts the stored credentials are wiped (defensive
///   limit — at this point the device is either brute-forced or forgotten)
class PinService {
  static const _pinKey = 'app_pin_hash';
  static const _attemptCountKey = 'app_pin_attempts';
  static const _lockoutUntilKey = 'app_pin_lockout_until';
  static const _secure = FlutterSecureStorage();

  /// Defensive limit: wipe all credentials after this many consecutive
  /// failed attempts. The exponential backoff makes this practically
  /// unreachable (~25 hours of cumulative lockout), so reaching it means
  /// either a sophisticated attacker or a forgotten PIN.
  static const _wipeAfterAttempts = 20;

  /// Backoff schedule (ms) keyed by attempt count after the threshold.
  /// Attempts 1-4: no lockout (1s, 1s, 1s, 1s — first 4 are free)
  /// Attempts 5+: 5s, 30s, 1m, 5m, 15m, 1h, 4h, 24h (capped at 24h)
  static const _maxBackoffMs = 24 * 60 * 60 * 1000; // 24h

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

  static Future<void> _delete() async {
    if (_useSecure) {
      await _secure.delete(key: _pinKey);
    } else {
      final p = await _prefs;
      await p.remove(_pinKey);
    }
  }

  /// Check if a PIN is currently set.
  static Future<bool> hasPin() async {
    final value = await _read();
    return value != null && value.isNotEmpty;
  }

  /// Store a new PIN (PBKDF2 hashed with random salt).
  /// Resets the failure counter — fresh start after a successful set.
  static Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = _deriveKey(pin, salt);
    await _write('${base64Encode(salt)}:${base64Encode(hash)}');
    await _resetAttempts();
  }

  /// Verify a PIN against the stored hash, applying lockout if needed.
  ///
  /// Callers should check [lockoutRemaining] first to display a "Try again
  /// in X seconds" message, then call [verifyPin] and branch on the result.
  /// A wrong attempt increments the failure counter; a successful attempt
  /// resets it.
  static Future<PinVerifyResult> verifyPin(String pin) async {
    // Check lockout first — refuse to even attempt verification during one.
    if (await isLockedOut()) {
      return PinVerifyResult.locked;
    }

    final stored = await _read();
    if (stored == null) return PinVerifyResult.wrong;

    // Backward compat: old DJB2 format (no colon, 8 hex chars)
    if (!stored.contains(':')) {
      if (stored == _legacyHash(pin)) {
        await setPin(pin); // upgrade to PBKDF2
        return PinVerifyResult.success;
      }
      await _recordFailure();
      return PinVerifyResult.wrong;
    }

    final parts = stored.split(':');
    if (parts.length != 2) {
      // Corrupted entry — treat as wrong PIN but don't trigger wipe.
      await _recordFailure();
      return PinVerifyResult.wrong;
    }
    final salt = base64Decode(parts[0]);
    final expectedHash = base64Decode(parts[1]);
    final actualHash = _deriveKey(pin, salt);
    if (_constantTimeEquals(expectedHash, actualHash)) {
      await _resetAttempts();
      return PinVerifyResult.success;
    }

    await _recordFailure();
    return PinVerifyResult.wrong;
  }

  /// How many milliseconds remain on the current lockout, or 0 if not locked.
  static Future<Duration> lockoutRemaining() async {
    final p = await _prefs;
    final untilMs = p.getInt(_lockoutUntilKey);
    if (untilMs == null) return Duration.zero;
    final remaining = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      // Lockout expired — clear it.
      await p.remove(_lockoutUntilKey);
      return Duration.zero;
    }
    return Duration(milliseconds: remaining);
  }

  /// Whether the PIN is currently locked out (lockout timer not yet expired).
  static Future<bool> isLockedOut() async {
    return (await lockoutRemaining()) > Duration.zero;
  }

  /// Current consecutive failure count (0 after a successful verify).
  static Future<int> attemptCount() async {
    final p = await _prefs;
    return p.getInt(_attemptCountKey) ?? 0;
  }

  /// Remove the PIN lock and clear all security state.
  static Future<void> removePin() async {
    await _delete();
    await _resetAttempts();
  }

  /// Reset the failure counter and lockout timer. Called after a successful
  /// verify or when a new PIN is set.
  static Future<void> _resetAttempts() async {
    final p = await _prefs;
    await p.remove(_attemptCountKey);
    await p.remove(_lockoutUntilKey);
  }

  /// Record a failed verification and start a new lockout if the attempt
  /// count crosses the backoff threshold. After [_wipeAfterAttempts]
  /// consecutive failures, all stored credentials are wiped.
  static Future<void> _recordFailure() async {
    final p = await _prefs;
    final count = (p.getInt(_attemptCountKey) ?? 0) + 1;
    await p.setInt(_attemptCountKey, count);

    if (count >= _wipeAfterAttempts) {
      // Defensive wipe — assume compromise. Clear PIN, all secure storage
      // (if used), and all SharedPreferences. The user must re-add providers.
      await _delete();
      if (_useSecure) {
        try {
          await _secure.deleteAll();
        } catch (_) {
          // ignore — already cleared local state
        }
      }
      await p.clear();
      return;
    }

    if (count >= 5) {
      // Exponential backoff: 5s, 30s, 1m, 5m, 15m, 1h, 4h, 24h, then capped.
      const schedule = <int>[
        5 * 1000,
        30 * 1000,
        60 * 1000,
        5 * 60 * 1000,
        15 * 60 * 1000,
        60 * 60 * 1000,
        4 * 60 * 60 * 1000,
        24 * 60 * 60 * 1000,
      ];
      final index = (count - 5).clamp(0, schedule.length - 1);
      final backoffMs = schedule[index].clamp(0, _maxBackoffMs);
      final untilMs = DateTime.now().millisecondsSinceEpoch + backoffMs;
      await p.setInt(_lockoutUntilKey, untilMs);
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
