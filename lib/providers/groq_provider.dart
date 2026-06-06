import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
class GroqProvider extends AIProvider {
  GroqProvider(super.config);

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

  @override
  Future<BalanceInfo> getBalance() async {
    try {
      // Groq doesn't have a dedicated balance endpoint — use models list as liveness check
      final resp = await http.get(
        Uri.parse('$baseUrl/openai/v1/models'),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        return BalanceInfo(
          providerId: providerId,
          providerName: type.displayName,
          balance: 0,
          currency: 'USD',
          lastUpdated: DateTime.now(),
          status: BalanceStatus.active,
          rawResponse: {'note': 'Groq does not expose balance via API. Key is valid.'},
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
    return const UsageInfo(spentThisMonth: 0, totalCredits: 0);
  }

  @override
  bool get supportsBalance => false;
}
