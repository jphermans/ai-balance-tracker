import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class OpenRouterProvider extends AIProvider {
  OpenRouterProvider(super.config);

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
        return list.map<ModelInfo>((m) {
          final pricing = m['pricing'] as Map<String, dynamic>?;
          final inputPerToken =
              double.tryParse(pricing?['prompt']?.toString() ?? '');
          final outputPerToken =
              double.tryParse(pricing?['completion']?.toString() ?? '');
          final arch =
              m['architecture'] as Map<String, dynamic>?;
          final modality =
              arch?['modality'] as String?;
          return ModelInfo(
            id: (m['id'] as String?) ?? '',
            displayName: (m['name'] as String?) ?? (m['id'] as String?) ?? '',
            inputPricePer1M: inputPerToken != null ? inputPerToken * 1000000 : null,
            outputPricePer1M: outputPerToken != null ? outputPerToken * 1000000 : null,
            contextWindow: (m['context_length'] as num?)?.toInt(),
            capabilities: modality,
          );
        }).toList();
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
        Uri.parse('$baseUrl/v1/credits'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        // Response is wrapped in { data: { ... } }
        final data = raw['data'] as Map<String, dynamic>? ?? raw;
        final totalCredits =
            double.tryParse(data['total_credits']?.toString() ?? '0') ?? 0;
        final totalUsage =
            double.tryParse(data['total_usage']?.toString() ?? '0') ?? 0;
        final remaining = totalCredits - totalUsage;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: remaining,
          currency: 'USD',
          totalSpent: totalUsage,
          totalCredits: totalCredits,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: raw,
        );
      } else if (resp.statusCode == 401) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'USD',
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
        currency: 'USD',
        lastUpdated: DateTime.now(),
        status: handleError(e),
      );
    }
  }

  @override
  Future<UsageInfo> getUsage() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/credits'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        final data = raw['data'] as Map<String, dynamic>? ?? raw;
        return UsageInfo(
          spentThisMonth:
              double.tryParse(data['total_usage']?.toString() ?? '0') ?? 0,
          totalCredits:
              double.tryParse(data['total_credits']?.toString() ?? '0') ?? 0,
        );
      }
      throw Exception();
    } catch (_) {
      return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
    }
  }
}
