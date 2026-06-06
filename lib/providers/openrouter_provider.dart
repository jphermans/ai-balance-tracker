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
        final data = jsonDecode(resp.body);
        final credits = (data['total_credits'] as num?)?.toDouble() ?? 0;
        final used = (data['total_usage'] as num?)?.toDouble() ?? 0;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: credits - used,
          currency: 'credits',
          totalSpent: used,
          totalCredits: credits,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: data,
        );
      } else if (resp.statusCode == 401) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'credits',
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
        currency: 'credits',
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
