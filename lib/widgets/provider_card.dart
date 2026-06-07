import 'package:flutter/material.dart';
import '../models/balance_info.dart';
import '../theme/app_theme.dart';

class ProviderCard extends StatelessWidget {
  final BalanceInfo info;
  final VoidCallback? onTap;

  const ProviderCard({super.key, required this.info, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance threshold indicator strip
            if (info.supportsBalance && info.status == BalanceStatus.active)
              Container(
                width: 4,
                color: _balanceColor(info.balance),
              ),
            // Card content
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ProviderIcon(type: info.providerId),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              info.providerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _StatusBadge(status: info.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatBalance(info.balance),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: info.supportsBalance &&
                                      info.status == BalanceStatus.active
                                  ? _balanceColor(info.balance)
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              info.currency,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (info.totalSpent != null) ...[
                        LinearProgressIndicator(
                          value: info.totalCredits != null && info.totalCredits! > 0
                              ? (info.totalSpent! / info.totalCredits!).clamp(0.0, 1.0)
                              : null,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Updated ${_formatTimestamp(info.lastUpdated)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // Banner for providers without balance API support
                      if (!info.supportsBalance) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Balance check not supported — key validation only',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ), // InkWell
            ), // Expanded
            ], // Row children
          ), // IntrinsicHeight
        ), // Card
      );
  }

  /// Returns a color based on balance thresholds:
  /// - Red: < 5 (critical)
  /// - Orange: 5 to < 10 (warning)
  /// - Green: >= 10 (healthy)
  Color _balanceColor(double balance) {
    if (balance < 5) return Colors.red;
    if (balance < 10) return Colors.orange;
    return Colors.green;
  }

  String _formatBalance(double balance) {
    if (balance == 0) return '0.00';
    return balance.toStringAsFixed(2);
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ProviderIcon extends StatelessWidget {
  final String type;
  const _ProviderIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          type.substring(0, 2).toUpperCase(),
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BalanceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BalanceStatus.active => StatusColors.active(context),
      BalanceStatus.invalidKey => StatusColors.invalidKey(context),
      _ => StatusColors.unavailable(context),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
