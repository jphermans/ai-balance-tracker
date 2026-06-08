import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class SiliconFlowProvider extends AIProvider {
  SiliconFlowProvider(super.config);

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
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/user/info'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final balance = double.tryParse(
              (data['totalBalance'] ?? data['balance'] ?? '0').toString(),
            ) ??
            0;
        final status = data['status'] as String? ?? 'active';

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: balance,
          currency: 'CNY',
          lastUpdated: DateTime.now(),
          status: status == 'active' ? BalanceStatus.active : BalanceStatus.unavailable,
          rawResponse: data,
        );
      } else if (resp.statusCode == 401) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'CNY',
          lastUpdated: DateTime.now(),
          status: BalanceStatus.invalidKey,
        );
      }

      throw Exception('HTTP ${resp.statusCode}');
    } catch (e) {
      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'CNY',
        lastUpdated: DateTime.now(),
        status: handleError(e),
      );
    }
  }

  @override
  Future<UsageInfo> getUsage() async {
    return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
  }
}
