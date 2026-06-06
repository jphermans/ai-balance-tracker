import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';

class OpenRouterProvider extends AIProvider {
  OpenRouterProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

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
