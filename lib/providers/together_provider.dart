import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class TogetherProvider extends AIProvider {
  TogetherProvider(super.config);

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
        return list.map<ModelInfo>((m) => ModelInfo(
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
      // Together billing info
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/billing'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final balance = (data['credit_balance'] as num?)?.toDouble() ??
            (data['balance'] as num?)?.toDouble() ?? 0;
        final totalCredits = (data['total_credits'] as num?)?.toDouble() ?? 0;
        final totalUsage = (data['total_usage'] as num?)?.toDouble() ?? 0;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: balance,
          currency: 'USD',
          totalSpent: totalUsage,
          totalCredits: totalCredits,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: data,
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
        Uri.parse('$baseUrl/v1/billing'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return UsageInfo(
          spentThisMonth: (data['total_usage'] as num?)?.toDouble() ?? 0,
          totalCredits: (data['total_credits'] as num?)?.toDouble() ?? 0,
        );
      }
      throw Exception();
    } catch (_) {
      return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
    }
  }
}
