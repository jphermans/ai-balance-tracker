import 'package:flutter_test/flutter_test.dart';
import 'package:ai_balance_tracker/services/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncryptionService round-trip', () {
    test('encrypt → tryDecrypt returns original plaintext', () {
      const userId = 'test-user-123';
      const plaintext = 'sk-proj-AbCdEf123456';

      final encrypted = EncryptionService.encrypt(plaintext, userId);
      expect(encrypted, startsWith('AES256GCM:'));

      final decrypted = EncryptionService.tryDecrypt(encrypted, userId);
      expect(decrypted, plaintext);
    });

    test('each encryption produces different ciphertext (random IV)', () {
      const userId = 'test-user-123';
      const plaintext = 'sk-proj-AbCdEf123456';

      final a = EncryptionService.encrypt(plaintext, userId);
      final b = EncryptionService.encrypt(plaintext, userId);
      expect(a, isNot(b)); // different IV → different ciphertext
    });

    test('empty plaintext round-trips to empty', () {
      expect(EncryptionService.encrypt('', 'u'), '');
      expect(EncryptionService.tryDecrypt('', 'u'), '');
    });

    test('null input returns empty', () {
      expect(EncryptionService.tryDecrypt(null, 'u'), '');
    });
  });

  group('EncryptionService backward compat', () {
    test('plaintext passthrough (no AES256GCM prefix) returns as-is', () {
      const legacyPlaintext = 'sk-legacy-not-encrypted';
      expect(EncryptionService.tryDecrypt(legacyPlaintext, 'u'),
          legacyPlaintext);
    });
  });

  group('EncryptionService failure modes (issue #43 fix)', () {
    const userId = 'test-user-123';

    test('malformed base64 returns null (was: threw FormatException)', () {
      final result = EncryptionService.tryDecrypt(
          'AES256GCM:!!!not-base64!!!', userId);
      expect(result, isNull);
    });

    test('too-short ciphertext returns null', () {
      // Valid base64 but fewer than IV+tag (28 bytes) — should not crash.
      final result = EncryptionService.tryDecrypt('AES256GCM:AAAA', userId);
      expect(result, isNull);
    });

    test('tampered ciphertext returns null (GCM auth fails)', () {
      final encrypted = EncryptionService.encrypt('secret-key', userId);
      // Flip a character in the middle of the base64 payload.
      final b64 = encrypted.substring('AES256GCM:'.length);
      final tampered =
          'AES256GCM:${b64.substring(0, 10)}A${b64.substring(11)}';
      final result = EncryptionService.tryDecrypt(tampered, userId);
      expect(result, isNull);
    });

    test('wrong userId fails GCM auth, returns null', () {
      final encrypted = EncryptionService.encrypt('secret-key', 'alice');
      final result = EncryptionService.tryDecrypt(encrypted, 'bob');
      expect(result, isNull);
    });

    test('cross-device: same project key, different userIds round-trips', () {
      // Simulates: device A signs in (userId=A), encrypts and uploads.
      // Device B signs in (userId=B), downloads and decrypts. With the
      // project-key derivation both devices can decrypt each other's
      // data. With the legacy per-user-id derivation, this fails.
      EncryptionService.initialize(
        supabaseUrl: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_abc123',
      );
      const deviceAUserId = 'device-a-anon-user-id';
      const deviceBUserId = 'device-b-anon-user-id';

      final encrypted = EncryptionService.encrypt('sk-cross-device', deviceAUserId);
      final decrypted = EncryptionService.tryDecrypt(encrypted, deviceBUserId);
      expect(decrypted, 'sk-cross-device');
    });

    test('different project key fails GCM auth, returns null', () {
      EncryptionService.initialize(
        supabaseUrl: 'https://project-a.supabase.co',
        publishableKey: 'sb_publishable_aaa',
      );
      final encrypted = EncryptionService.encrypt('sk-a', 'any-user');

      // Switch to a different project's key material
      EncryptionService.initialize(
        supabaseUrl: 'https://project-b.supabase.co',
        publishableKey: 'sb_publishable_bbb',
      );
      final decrypted = EncryptionService.tryDecrypt(encrypted, 'any-user');
      expect(decrypted, isNull);
    });

    test('deprecated decrypt() degrades null to empty string', () {
      // ignore: deprecated_member_use_from_same_package
      final result = EncryptionService.decrypt('AES256GCM:garbage', userId);
      expect(result, '');
    });
  });
}
