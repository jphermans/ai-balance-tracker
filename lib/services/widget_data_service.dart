import 'package:flutter/services.dart';
import '../models/balance_info.dart';

/// Writes balance summary data to iOS App Group UserDefaults
/// so the native WidgetKit widget can display it.
class WidgetDataService {
  static const _channel = MethodChannel('com.jphermans.ai-balance-tracker/widget');

  /// Update the widget with current balances.
  /// Call this after every balance refresh.
  static Future<void> updateFromBalances(Map<String, BalanceInfo> balances) async {
    final active = balances.values
        .where((b) => b.status == BalanceStatus.active)
        .toList();
    final totalBalance = active.fold<double>(0, (sum, b) => sum + b.balance);
    final currency = active.isNotEmpty ? active.first.currency : 'USD';
    final nowMs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _channel.invokeMethod('updateWidget', {
        'totalBalance': totalBalance,
        'providerCount': active.length,
        'currency': currency,
        'lastUpdated': nowMs,
      });
    } on MissingPluginException {
      // Widget not available (Android, or running in test)
    }
  }
}
