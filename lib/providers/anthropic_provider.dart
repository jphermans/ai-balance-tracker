import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';

class AnthropicProvider extends AIProvider {
  AnthropicProvider(super.config);

  @override
  Map<String, String> get headers => {
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      };

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      // Anthropic usage endpoint (requires organization ID lookup)
      final orgsResp = await http.get(
        Uri.parse('$baseUrl/v1/organizations'),
        headers: headers,
      );

      if (orgsResp.statusCode != 200) {
        if (orgsResp.statusCode == 401 || orgsResp.statusCode == 403) {
          return BalanceInfo(
            providerId: providerId,
            providerName: type.displayName,
            balance: 0,
            currency: 'USD',
            lastUpdated: DateTime.now(),
            status: BalanceStatus.invalidKey,
          );
        }
        throw Exception('HTTP ${orgsResp.statusCode}');
      }

      final orgs = jsonDecode(orgsResp.body)['data'] as List;
      if (orgs.isEmpty) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'USD',
          lastUpdated: DateTime.now(),
          status: BalanceStatus.unavailable,
        );
      }

      final orgId = config.orgId ?? orgs.first['id'];
      final usageResp = await http.get(
        Uri.parse('$baseUrl/v1/organizations/$orgId/usage'),
        headers: headers,
      );

      if (usageResp.statusCode == 200) {
        final usageData = jsonDecode(usageResp.body);
        final totalUsed = (usageData['total_used_credits'] as num?)?.toDouble() ?? 0;
        final totalCredits = (usageData['total_credits'] as num?)?.toDouble() ?? 0;
        final spentThisMonth = (usageData['used_credits_this_month'] as num?)?.toDouble() ?? 0;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: totalCredits - totalUsed,
          currency: 'credits',
          totalSpent: totalUsed,
          totalCredits: totalCredits,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: usageData,
        );
      }

      throw Exception('HTTP ${usageResp.statusCode}');
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
      final orgsResp = await http.get(
        Uri.parse('$baseUrl/v1/organizations'),
        headers: headers,
      );
      if (orgsResp.statusCode != 200) throw Exception();

      final orgs = jsonDecode(orgsResp.body)['data'] as List;
      final orgId = config.orgId ?? (orgs.isNotEmpty ? orgs.first['id'] : null);
      if (orgId == null) throw Exception('No organization found');

      final resp = await http.get(
        Uri.parse('$baseUrl/v1/organizations/$orgId/usage'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return UsageInfo(
          spentThisMonth: (data['used_credits_this_month'] as num?)?.toDouble() ?? 0,
          totalCredits: (data['total_credits'] as num?)?.toDouble() ?? 0,
        );
      }
      throw Exception();
    } catch (_) {
      return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
    }
  }
}
