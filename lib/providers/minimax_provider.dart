import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class MinimaxProvider extends AIProvider {
  MinimaxProvider(super.config);

  @override
  Map<String, String> get headers => {
        'X-Api-Key': config.apiKey,
        'Content-Type': 'application/json',
      };

  @override
  Future<List<ModelInfo>> fetchModels() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/anthropic/v1/models'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        final list = (raw['data'] as List<dynamic>?) ?? [];
        return list.map<ModelInfo>((m) => ModelInfo.enriched(
          id: (m['id'] as String?) ?? '',
          displayName: (m['display_name'] as String?) ??
              (m['id'] as String?) ?? '',
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
      final resp = await http.get(
        Uri.parse('$baseUrl/anthropic/v1/models'),
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
          'note': 'MiniMax does not expose balance via API. '
              'Key validated via /anthropic/v1/models.',
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
        status: BalanceStatus.unavailable,
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
