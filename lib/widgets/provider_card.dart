import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/balance_info.dart';
import '../models/provider_config.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ProviderCard extends StatelessWidget {
  final BalanceInfo info;
  final VoidCallback? onDetailTap;
  final VoidCallback? onRefresh;
  final bool refreshing;

  const ProviderCard({
    super.key,
    required this.info,
    this.onDetailTap,
    this.onRefresh,
    this.refreshing = false,
  });

  Future<void> _openWebsite(BuildContext context) async {
    final typeName = info.providerId.split('_').first;
    final type = ProviderType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => ProviderType.openai,
    );
    final url = type.websiteUrl;

    if (url == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${info.providerName} has no public website'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      onTap: () => _openWebsite(context),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance threshold indicator strip
            if (info.supportsBalance && info.status == BalanceStatus.active)
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _balanceColor(info.balance),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            // Card content
            Expanded(
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
                        if (onDetailTap != null)
                          GestureDetector(
                            onTap: onDetailTap,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        if (onRefresh != null)
                          GestureDetector(
                            onTap: refreshing ? null : onRefresh,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: refreshing
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.6),
                                    ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        _StatusBadge(status: info.status),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: info.totalCredits != null &&
                                  info.totalCredits! > 0
                              ? (info.totalSpent! / info.totalCredits!)
                                  .clamp(0.0, 1.0)
                              : null,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Updated ${_formatTimestamp(info.lastUpdated)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!info.supportsBalance) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: Colors.amber.shade700),
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
            ),
          ],
        ),
      ),
    );
  }

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
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
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
