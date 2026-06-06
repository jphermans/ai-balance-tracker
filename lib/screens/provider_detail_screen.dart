import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../models/balance_info.dart';
import '../models/usage_info.dart';
import '../services/balance_service.dart';

class ProviderDetailScreen extends ConsumerStatefulWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderDetailScreen> createState() =>
      _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> {
  UsageInfo? _usage;
  bool _loadingUsage = false;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final configs = ref.read(providersProvider);
    final config = configs.where((c) => c.id == widget.providerId).firstOrNull;
    if (config == null) return;

    setState(() => _loadingUsage = true);
    try {
      final usage = await BalanceService.fetchUsage(config);
      setState(() => _usage = usage);
    } finally {
      setState(() => _loadingUsage = false);
    }
  }

  Future<void> _refresh() async {
    final configs = ref.read(providersProvider);
    final config = configs.where((c) => c.id == widget.providerId).firstOrNull;
    if (config == null) return;

    await ref.read(balancesProvider.notifier).refreshOne(config);
    await _loadUsage();
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(balancesProvider);
    final info = balances[widget.providerId];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (info == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(info.providerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${info.balance.toStringAsFixed(2)} ${info.currency}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Spent This Month',
                    value: _usage != null
                        ? '\$${_usage!.spentThisMonth.toStringAsFixed(2)}'
                        : '--',
                    icon: Icons.trending_up_rounded,
                    loading: _loadingUsage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total Credits',
                    value: info.totalCredits != null
                        ? '${info.totalCredits!.toStringAsFixed(2)} ${info.currency}'
                        : '--',
                    icon: Icons.savings_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Status',
                    value: info.status.displayName,
                    icon: Icons.circle_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Last Synced',
                    value: _formatTimestamp(info.lastUpdated),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Raw response toggle
            if (info.rawResponse != null)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Raw API Response'),
                  subtitle: const Text('Developer mode'),
                  initiallyExpanded: _showRaw,
                  onExpansionChanged: (expanded) =>
                      setState(() => _showRaw = expanded),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: colorScheme.surfaceContainerHighest,
                      child: SelectableText(
                        _formatJson(info.rawResponse!),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatJson(Map<String, dynamic> json) {
    return JsonEncoder.withIndent('  ').convert(json);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool loading;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (loading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
