import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';

class DeepSeekProvider extends AIProvider {
  DeepSeekProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/user/balance'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final balanceInfos = data['balance_infos'] as List?;
        double totalBalance = 0;

        if (balanceInfos != null && balanceInfos.isNotEmpty) {
          for (final info in balanceInfos) {
            totalBalance += (info['total_balance'] as num?)?.toDouble() ?? 0;
          }
        } else {
          totalBalance = (data['total_balance'] as num?)?.toDouble() ?? 0;
        }

        final currency = data['currency'] as String? ?? 'CNY';

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: totalBalance,
          currency: currency,
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
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
