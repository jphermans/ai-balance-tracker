import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_balance_tracker/services/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Wipe any leftover lockout state from a previous test.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // defaultTargetPlatform is Android in unit tests, which would route
    // PinService through FlutterSecureStorage (Keychain). The Linux test
    // runner has no Keychain implementation, so force the platform to
    // Linux — this makes PinService use SharedPreferences instead.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('PinService — setPin / verifyPin (issue #43 fix #1)', () {
    test('setPin then verifyPin with correct PIN succeeds', () async {
      await PinService.setPin('1234');
      expect(await PinService.hasPin(), isTrue);
      final result = await PinService.verifyPin('1234');
      expect(result, PinVerifyResult.success);
    });

    test('verifyPin with wrong PIN returns wrong, not success', () async {
      await PinService.setPin('1234');
      final result = await PinService.verifyPin('9999');
      expect(result, PinVerifyResult.wrong);
    });

    test('verifyPin before setPin returns wrong (no crash)', () async {
      final result = await PinService.verifyPin('1234');
      expect(result, PinVerifyResult.wrong);
    });

    test('successful verify resets attempt counter', () async {
      await PinService.setPin('1234');
      // Burn 2 wrong attempts.
      await PinService.verifyPin('0000');
      await PinService.verifyPin('0000');
      expect(await PinService.attemptCount(), 2);

      // Successful verify should clear the counter.
      final ok = await PinService.verifyPin('1234');
      expect(ok, PinVerifyResult.success);
      expect(await PinService.attemptCount(), 0);
    });
  });

  group('PinService — lockout (issue #43 fix #1)', () {
    test('5 wrong attempts triggers lockout', () async {
      await PinService.setPin('1234');
      for (var i = 0; i < 5; i++) {
        final r = await PinService.verifyPin('0000');
        expect(r, PinVerifyResult.wrong);
      }
      // 6th attempt should be locked, not just wrong.
      final r = await PinService.verifyPin('1234');
      expect(r, PinVerifyResult.locked);
      expect(await PinService.isLockedOut(), isTrue);
    });

    test('locked-out state refuses even correct PIN', () async {
      await PinService.setPin('1234');
      // Trigger lockout.
      for (var i = 0; i < 5; i++) {
        await PinService.verifyPin('0000');
      }
      // Correct PIN — should still be locked.
      final r = await PinService.verifyPin('1234');
      expect(r, PinVerifyResult.locked);
    });

    test('lockoutRemaining returns positive duration during lockout', () async {
      await PinService.setPin('1234');
      for (var i = 0; i < 5; i++) {
        await PinService.verifyPin('0000');
      }
      final remaining = await PinService.lockoutRemaining();
      expect(remaining.inMilliseconds, greaterThan(0));
    });

    test('setPin clears existing lockout', () async {
      await PinService.setPin('1234');
      for (var i = 0; i < 5; i++) {
        await PinService.verifyPin('0000');
      }
      expect(await PinService.isLockedOut(), isTrue);

      // Setting a new PIN should clear lockout state.
      await PinService.setPin('5678');
      expect(await PinService.isLockedOut(), isFalse);
      expect(await PinService.attemptCount(), 0);
    });

    test('removePin clears lockout and counter', () async {
      await PinService.setPin('1234');
      for (var i = 0; i < 3; i++) {
        await PinService.verifyPin('0000');
      }
      await PinService.removePin();
      expect(await PinService.attemptCount(), 0);
      expect(await PinService.isLockedOut(), isFalse);
      expect(await PinService.hasPin(), isFalse);
    });
  });
}
