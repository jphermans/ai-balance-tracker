import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/provider_config.dart';

/// Stub provider for AI services without a dedicated balance/credits API.
/// Validates the API key with a lightweight liveness check.
class StubProvider extends AIProvider {
  StubProvider(super.config);

  @override
  Map<String, String> get headers {
    // Some providers use different header formats
    if (type == ProviderType.huggingface) {
      return {'Authorization': 'Bearer ${config.apiKey}'};
    }
    return {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      final uri = Uri.parse(_checkUrl);
      final resp = type == ProviderType.googleAI
          ? await http.get(uri)
          : await http.get(uri, headers: headers);

      final valid = resp.statusCode != 401 && resp.statusCode != 403;

      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'N/A',
        lastUpdated: DateTime.now(),
        status: valid ? BalanceStatus.active : BalanceStatus.invalidKey,
        rawResponse: {
          'note': '${type.displayName} does not expose balance via API. '
              'Key validation only.',
          'statusCode': resp.statusCode,
        },
      );
    } catch (e) {
      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'N/A',
        lastUpdated: DateTime.now(),
        status: BalanceStatus.unavailable,
      );
    }
  }

  @override
  Future<UsageInfo> getUsage() async {
    return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
  }

  @override
  bool get supportsBalance => false;

  @override
  bool get supportsUsage => false;

  String get _checkUrl {
    switch (type) {
      case ProviderType.googleAI:
        return '$baseUrl/v1beta/models?key=${config.apiKey}';
      case ProviderType.xai:
        return '$baseUrl/v1/models';
      case ProviderType.cohere:
        return '$baseUrl/v2/check-api-key';
      case ProviderType.mistral:
        return '$baseUrl/v1/models';
      case ProviderType.fireworks:
        return '$baseUrl/v1/models';
      case ProviderType.perplexity:
        return '$baseUrl/chat/completions';
      case ProviderType.novita:
        return '$baseUrl/v1/models';
      case ProviderType.siliconflow:
        return '$baseUrl/v1/models';
      case ProviderType.moonshot:
        return '$baseUrl/v1/models';
      case ProviderType.cerebras:
        return '$baseUrl/v1/models';
      case ProviderType.replicate:
        return '$baseUrl/v1/models';
      case ProviderType.huggingface:
        return '$baseUrl/api/whoami-v2';
      case ProviderType.sambanova:
        return '$baseUrl/v1/models';
      case ProviderType.ai21:
        return '$baseUrl/studio/v1/models';
      default:
        return '$baseUrl/v1/models';
    }
  }
}
