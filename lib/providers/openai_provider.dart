import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';

class OpenAIProvider extends AIProvider {
  OpenAIProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
        if (config.orgId != null) 'OpenAI-Organization': config.orgId!,
      };

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      // OpenAI billing/subscription endpoint
      final subResp = await http.get(
        Uri.parse('$baseUrl/v1/dashboard/billing/subscription'),
        headers: headers,
      );

      if (subResp.statusCode == 200) {
        final subData = jsonDecode(subResp.body);
        final hardLimit = (subData['hard_limit_usd'] as num?)?.toDouble() ?? 0;
        final softLimit = (subData['soft_limit_usd'] as num?)?.toDouble() ?? 0;

        // Get usage for current month
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);
        final usageResp = await http.get(
          Uri.parse(
            '$baseUrl/v1/dashboard/billing/usage'
            '?start_date=${startDate.toIso8601String().split('T')[0]}'
            '&end_date=${now.toIso8601String().split('T')[0]}',
          ),
          headers: headers,
        );

        double spent = 0;
        if (usageResp.statusCode == 200) {
          final usageData = jsonDecode(usageResp.body);
          spent = (usageData['total_usage'] as num?)?.toDouble() ?? 0;
        }

        final remaining = hardLimit > 0 ? hardLimit - spent : softLimit - spent;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: remaining,
          currency: 'USD',
          totalSpent: spent,
          totalCredits: hardLimit > 0 ? hardLimit : softLimit,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: subData,
        );
      } else if (subResp.statusCode == 401 || subResp.statusCode == 403) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'USD',
          lastUpdated: DateTime.now(),
          status: BalanceStatus.invalidKey,
        );
      }

      throw Exception('HTTP ${subResp.statusCode}');
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
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final resp = await http.get(
        Uri.parse(
          '$baseUrl/v1/dashboard/billing/usage'
          '?start_date=${startDate.toIso8601String().split('T')[0]}'
          '&end_date=${now.toIso8601String().split('T')[0]}',
        ),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return UsageInfo(
          spentThisMonth: (data['total_usage'] as num?)?.toDouble() ?? 0,
          totalCredits: 0,
        );
      }
      throw Exception('HTTP ${resp.statusCode}');
    } catch (e) {
      return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
    }
  }
}
