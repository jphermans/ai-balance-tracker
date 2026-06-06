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
      // OpenAI credit grants endpoint
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/dashboard/billing/credit_grants'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final totalAvailable =
            double.tryParse(data['total_available']?.toString() ?? '0') ?? 0;
        final totalGranted =
            double.tryParse(data['total_granted']?.toString() ?? '0') ?? 0;
        final totalUsed =
            double.tryParse(data['total_used']?.toString() ?? '0') ?? 0;

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: totalAvailable,
          currency: 'USD',
          totalSpent: totalUsed,
          totalCredits: totalGranted,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: data,
        );
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
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
        Uri.parse('$baseUrl/v1/dashboard/billing/credit_grants'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return UsageInfo(
          spentThisMonth:
              double.tryParse(data['total_used']?.toString() ?? '0') ?? 0,
          totalCredits:
              double.tryParse(data['total_granted']?.toString() ?? '0') ?? 0,
        );
      }
      throw Exception();
    } catch (_) {
      return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
    }
  }
}
