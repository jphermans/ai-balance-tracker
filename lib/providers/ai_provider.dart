import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../models/provider_config.dart';

/// Abstract base for all AI provider adapters.
/// Each provider implements balance/usage checking through its own API.
abstract class AIProvider {
  final ProviderConfig config;

  const AIProvider(this.config);

  String get providerId => config.id;
  ProviderType get type => config.type;
  String get baseUrl => config.customEndpoint ?? type.baseUrl;

  /// Fetch the current balance from the provider's API.
  Future<BalanceInfo> getBalance();

  /// Fetch usage statistics from the provider's API.
  Future<UsageInfo> getUsage();

  /// Build authorization headers for API requests.
  Map<String, String> get headers;

  /// Whether this provider supports balance checking.
  bool get supportsBalance => true;

  /// Whether this provider supports usage statistics.
  bool get supportsUsage => true;

  /// Handle API errors and return appropriate BalanceStatus.
  BalanceStatus handleError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized') || msg.contains('invalid')) {
      return BalanceStatus.invalidKey;
    }
    return BalanceStatus.unavailable;
  }
}
