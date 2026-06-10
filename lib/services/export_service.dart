import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import '../models/balance_info.dart';

/// Generates and shares a CSV export of all provider balances.
class ExportService {
  const ExportService._();

  /// Export balances to CSV and open the system share sheet.
  static Future<void> exportBalances(Map<String, BalanceInfo> balances) async {
    final rows = <List<String>>[
      ['Provider', 'Balance', 'Currency', 'Status', 'Last Updated'],
    ];

    for (final entry in balances.entries) {
      final info = entry.value;
      rows.add([
        info.providerName,
        info.balance.toStringAsFixed(2),
        info.currency,
        info.status.displayName,
        info.lastUpdated.toIso8601String(),
      ]);
    }

    final csv = Csv().asCodec().encode(rows);

    if (kIsWeb) {
      await SharePlus.instance.share(ShareParams(text: csv));
    } else {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ai_balance_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'AI Balance Tracker export',
      ));
    }
  }
}
