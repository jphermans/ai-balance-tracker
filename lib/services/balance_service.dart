import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/provider_config.dart';
import '../providers/provider_registry.dart';

/// Service that orchestrates balance and usage fetching across all providers.
class BalanceService {
  const BalanceService._();

  /// Fetch balance for a single provider configuration.
  static Future<BalanceInfo> fetchBalance(ProviderConfig config) async {
    final provider = ProviderRegistry.create(config);
    return provider.getBalance();
  }

  /// Fetch usage for a single provider configuration.
  static Future<UsageInfo> fetchUsage(ProviderConfig config) async {
    final provider = ProviderRegistry.create(config);
    return provider.getUsage();
  }

  /// Fetch balances for all enabled providers in parallel.
  static Future<List<BalanceInfo>> fetchAllBalances(
    List<ProviderConfig> configs,
  ) async {
    final enabled = configs.where((c) => c.enabled).toList();
    final futures = enabled.map((c) => fetchBalance(c));
    final results = await Future.wait(futures);
    return results;
  }

  /// Refresh a single provider's balance.
  static Future<BalanceInfo> refreshProvider(ProviderConfig config) async {
    return fetchBalance(config);
  }
}
