import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/balance_snapshot.dart';

class HistoryService {
  static const _prefix = 'history_';

  /// Record a balance snapshot for today. Overwrites if one already exists for today.
  static Future<void> recordSnapshot({
    required String providerId,
    required double balance,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$providerId';
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final raw = prefs.getString(key);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};

    map[todayKey] = {
      'providerId': providerId,
      'balance': balance,
      'date': today.toIso8601String(),
    };

    await prefs.setString(key, jsonEncode(map));
  }

  /// Get snapshots for [providerId] from the last [days] days.
  static Future<List<BalanceSnapshot>> getSnapshots({
    required String providerId,
    required int days,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$providerId';
    final raw = prefs.getString(key);
    if (raw == null) return [];

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    final snapshots = <BalanceSnapshot>[];
    for (final entry in map.entries) {
      final snapshot = BalanceSnapshot.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (snapshot.date.isAfter(cutoff)) {
        snapshots.add(snapshot);
      }
    }

    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  /// Remove all history for a provider.
  static Future<void> clearHistory(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$providerId');
  }
}
