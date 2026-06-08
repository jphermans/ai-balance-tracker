import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class MoonshotProvider extends AIProvider {
  MoonshotProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
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
      final url = '$baseUrl/v1/users/me/balance';
      final resp = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        // Response: { code: 0, data: { available_balance, voucher_balance, cash_balance }, status: true }
        final data = raw['data'] as Map<String, dynamic>? ?? raw;
        final balance = (data['available_balance'] as num?)?.toDouble() ?? 0;
        final currency = 'CNY';

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: balance,
          currency: currency,
          totalSpent: null,
          totalCredits: balance,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: raw,
        );
      }

      // Capture error body for debugging (visible in Developer Mode)
      String errorBody = '';
      try {
        errorBody = resp.body;
      } catch (_) {}

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'CNY',
          lastUpdated: DateTime.now(),
          status: BalanceStatus.invalidKey,
          rawResponse: {'error': 'HTTP ${resp.statusCode}', 'body': errorBody},
        );
      }

      throw Exception('HTTP ${resp.statusCode}: $errorBody');
    } catch (e) {
      return BalanceInfo(
        providerId: providerId,
        providerName: type.displayName,
        balance: 0,
        currency: 'USD',
        lastUpdated: DateTime.now(),
        status: handleError(e),
        rawResponse: {'error': e.toString()},
      );
    }
  }

  @override
  Future<UsageInfo> getUsage() async {
    return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
  }
}
