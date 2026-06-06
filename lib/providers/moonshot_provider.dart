import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';

class MoonshotProvider extends AIProvider {
  MoonshotProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/v1/users/me/balance'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        // Response: { data: { available_balance, voucher_balance, cash_balance } }
        final data = raw['data'] as Map<String, dynamic>? ?? raw;
        final balance = double.tryParse(
              (data['available_balance'] ??
                      data['balance'] ??
                      data['credit'] ??
                      data['total_balance'] ??
                      '0')
                  .toString(),
            ) ??
            0;
        final voucherBalance = double.tryParse(
              (data['voucher_balance'] ?? '0').toString(),
            ) ??
            0;
        final cashBalance = double.tryParse(
              (data['cash_balance'] ?? '0').toString(),
            ) ??
            0;
        final currency = (data['currency'] as String?) ?? 'CNY';

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
