import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/model_info.dart';

class DeepSeekProvider extends AIProvider {
  DeepSeekProvider(super.config);

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
      final resp = await http.get(
        Uri.parse('$baseUrl/user/balance'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final balanceInfos = data['balance_infos'] as List? ?? [];

        if (balanceInfos.isEmpty) {
          return BalanceInfo(
            providerId: providerId,
            providerName: type.displayName,
            balance: 0,
            currency: 'USD',
            lastUpdated: DateTime.now(),
            status: BalanceStatus.active,
            rawResponse: data,
          );
        }

        // Use first balance entry (primary currency)
        final info = balanceInfos.first as Map<String, dynamic>;
        final totalBalance =
            double.tryParse(info['total_balance']?.toString() ?? '0') ?? 0;
        final grantedBalance =
            double.tryParse(info['granted_balance']?.toString() ?? '0') ?? 0;
        final toppedUpBalance =
            double.tryParse(info['topped_up_balance']?.toString() ?? '0') ?? 0;
        final currency = info['currency'] as String? ?? 'CNY';

        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: totalBalance,
          currency: currency,
          totalSpent: grantedBalance + toppedUpBalance - totalBalance > 0
              ? grantedBalance + toppedUpBalance - totalBalance
              : null,
          totalCredits: grantedBalance + toppedUpBalance,
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
