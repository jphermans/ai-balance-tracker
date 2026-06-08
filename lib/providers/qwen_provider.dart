import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

/// Provider for Qwen models via Alibaba Cloud DashScope (OpenAI-compatible API).
/// DashScope does not expose a balance endpoint — key validation only.
class QwenProvider extends AIProvider {
  QwenProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

  @override
  Future<List<ModelInfo>> fetchModels() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/models'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        final list = (raw['data'] as List<dynamic>?) ?? [];
        return list.map<ModelInfo>((m) => ModelInfo.enriched(
          id: (m['id'] as String?) ?? '',
          displayName: (m['id'] as String?) ?? '',
        )).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      // Key validation via models listing (no dedicated balance endpoint)
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/models'),
        headers: headers,
      );

      final valid = resp.statusCode != 401 && resp.statusCode != 403;

      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'USD',
        lastUpdated: DateTime.now(),
        status: valid ? BalanceStatus.active : BalanceStatus.invalidKey,
        rawResponse: {
          'note': 'Qwen (Alibaba Cloud DashScope) does not expose balance via API. '
              'Check console at bailian.console.aliyun.com.',
          'statusCode': resp.statusCode,
        },
        supportsBalance: false,
      );
    } catch (e) {
      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'USD',
        lastUpdated: DateTime.now(),
        status: handleError(e),
        supportsBalance: false,
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
}
