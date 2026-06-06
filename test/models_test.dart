import 'package:flutter_test/flutter_test.dart';
import 'package:ai_balance_tracker/models/balance_info.dart';
import 'package:ai_balance_tracker/models/provider_config.dart';
import 'package:ai_balance_tracker/models/usage_info.dart';

void main() {
  group('BalanceInfo', () {
    test('fromJson creates correct object', () {
      final json = {
        'providerId': 'test_openai',
        'providerName': 'OpenAI',
        'balance': 42.50,
        'currency': 'USD',
        'totalSpent': 157.50,
        'totalCredits': 200.0,
        'lastUpdated': '2026-06-06T12:00:00.000Z',
        'status': 'active',
      };

      final info = BalanceInfo.fromJson(json);

      expect(info.providerId, 'test_openai');
      expect(info.balance, 42.50);
      expect(info.status, BalanceStatus.active);
    });

    test('toJson roundtrips', () {
      final original = BalanceInfo(
        providerId: 'test',
        providerName: 'Test',
        balance: 10.0,
        currency: 'USD',
        lastUpdated: DateTime(2026, 6, 6),
        status: BalanceStatus.active,
      );

      final copy = BalanceInfo.fromJson(original.toJson());
      expect(copy.providerId, original.providerId);
      expect(copy.balance, original.balance);
    });

    test('copyWith preserves unchanged fields', () {
      final original = BalanceInfo(
        providerId: 'test',
        providerName: 'Test',
        balance: 10.0,
        currency: 'USD',
        lastUpdated: DateTime(2026),
        status: BalanceStatus.active,
      );

      final updated = original.copyWith(balance: 20.0);
      expect(updated.balance, 20.0);
      expect(updated.providerId, 'test');
    });
  });

  group('UsageInfo', () {
    test('fromJson handles optional fields', () {
      final json = {
        'spentThisMonth': 25.0,
        'totalCredits': 100.0,
      };

      final info = UsageInfo.fromJson(json);
      expect(info.spentThisMonth, 25.0);
      expect(info.requestsThisMonth, isNull);
    });
  });

  group('ProviderConfig', () {
    test('fromJson/toJson roundtrip', () {
      final config = ProviderConfig(
        id: 'openai_1',
        type: ProviderType.openai,
        apiKey: 'sk-test123',
        orgId: 'org-456',
        customEndpoint: 'https://custom.example.com',
      );

      final copy = ProviderConfig.fromJson(config.toJson());
      expect(copy.id, config.id);
      expect(copy.type, config.type);
      expect(copy.apiKey, config.apiKey);
      expect(copy.orgId, config.orgId);
      expect(copy.customEndpoint, config.customEndpoint);
    });
  });

  group('ProviderType', () {
    test('displayName for all types is non-empty', () {
      for (final type in ProviderType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('hasBalanceEndpoint returns true for supported providers', () {
      expect(ProviderType.openai.hasBalanceEndpoint, isTrue);
      expect(ProviderType.anthropic.hasBalanceEndpoint, isTrue);
      expect(ProviderType.deepseek.hasBalanceEndpoint, isTrue);
      expect(ProviderType.openrouter.hasBalanceEndpoint, isTrue);
      expect(ProviderType.groq.hasBalanceEndpoint, isTrue);
      expect(ProviderType.together.hasBalanceEndpoint, isTrue);
      expect(ProviderType.cohere.hasBalanceEndpoint, isFalse);
    });
  });

  group('BalanceStatus', () {
    test('displayName returns human-readable text', () {
      expect(BalanceStatus.active.displayName, 'Active');
      expect(BalanceStatus.invalidKey.displayName, 'Invalid API Key');
    });
  });
}
