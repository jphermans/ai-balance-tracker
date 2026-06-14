import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/usage_info.dart';
import '../models/balance_snapshot.dart';
import '../services/balance_service.dart';
import '../services/history_service.dart';
import '../models/provider_config.dart' show ProviderType;
import '../models/model_info.dart';
import '../providers/provider_registry.dart';
import '../widgets/glass_card.dart';

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
  bool _showRaw = true;
  List<BalanceSnapshot> _snapshots = [];
  bool _loadingSnapshots = false;
  int _chartDays = 7;
  List<ModelInfo> _models = [];
  bool _loadingModels = false;
  bool _modelsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _loadSnapshots();
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

  Future<void> _loadSnapshots() async {
    setState(() => _loadingSnapshots = true);
    try {
      final snapshots = await HistoryService.getSnapshots(
        providerId: widget.providerId,
        days: 90,
      );
      setState(() => _snapshots = snapshots);
    } finally {
      setState(() => _loadingSnapshots = false);
    }
  }

  Future<void> _loadModels() async {
    if (_loadingModels) return;
    setState(() => _loadingModels = true);
    try {
      final configs = ref.read(providersProvider);
      final config = configs.where((c) => c.id == widget.providerId).firstOrNull;
      if (config != null) {
        final provider = ProviderRegistry.create(config);
        final models = await provider.fetchModels();
        setState(() {
          _models = models;
          _modelsLoaded = true;
        });
      }
    } finally {
      setState(() => _loadingModels = false);
    }
  }

  void _showModelsSheet() {
    if (!_modelsLoaded) {
      _loadModels();
      return;
    }
    if (_models.isEmpty) return;

    final info = ref.read(balancesProvider)[widget.providerId];
    final name = info?.providerName ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModelsSheet(models: _models, providerName: name),
    );
  }

  List<BalanceSnapshot> get _filteredSnapshots {
    final cutoff = DateTime.now().subtract(Duration(days: _chartDays));
    return _snapshots.where((s) => s.date.isAfter(cutoff)).toList();
  }

  Future<void> _refresh() async {
    final configs = ref.read(providersProvider);
    final config = configs.where((c) => c.id == widget.providerId).firstOrNull;
    if (config == null) return;

    await ref.read(balancesProvider.notifier).refreshOne(config);
    await _loadUsage();
    await _loadSnapshots();
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
            GlassCard(
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
            // Available models
            GlassCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: _showModelsSheet,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.model_training_rounded,
                          color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Models',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loadingModels
                                  ? 'Loading…'
                                  : _modelsLoaded
                                      ? '${_models.length} models • Tap to browse'
                                      : 'Tap to load models',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_loadingModels)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Balance history chart
            if (info.supportsBalance) ...[
              _BalanceChart(
                snapshots: _filteredSnapshots,
                currency: info.currency,
                loading: _loadingSnapshots,
              ),
              const SizedBox(height: 8),
              // Day toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DayChip(
                    label: '7D',
                    selected: _chartDays == 7,
                    onTap: () => setState(() => _chartDays = 7),
                  ),
                  const SizedBox(width: 8),
                  _DayChip(
                    label: '30D',
                    selected: _chartDays == 30,
                    onTap: () => setState(() => _chartDays = 30),
                  ),
                  const SizedBox(width: 8),
                  _DayChip(
                    label: '90D',
                    selected: _chartDays == 90,
                    onTap: () => setState(() => _chartDays = 90),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Raw API section — always visible for debugging
            GlassCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Raw API Response'),
                subtitle: Text(_apiUrlLabel(widget.providerId)),
                initiallyExpanded: _showRaw,
                onExpansionChanged: (expanded) =>
                    setState(() => _showRaw = expanded),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: colorScheme.surfaceContainerHighest,
                    child: SelectableText(
                      info.rawResponse != null
                          ? _formatJson(info.rawResponse!)
                          : 'No response data available.\n\n'
                              'URL: ${_apiUrl(widget.providerId)}\n'
                              'Status: ${info.status.displayName}',
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

  /// Returns the API endpoint URL for a provider type.
  String _apiUrl(String providerId) {
    try {
      final type = ProviderType.values.firstWhere((t) => t.name == providerId);
      return '${type.baseUrl}${_apiPath(type)}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Returns a shorter label for the subtitle.
  String _apiUrlLabel(String providerId) {
    final url = _apiUrl(providerId);
    if (url == 'unknown') return 'Developer mode';
    // Trim the protocol for compact display
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  /// Returns the known balance/validation API path for each provider type.
  String _apiPath(ProviderType type) {
    switch (type) {
      case ProviderType.openai:
        return '/v1/dashboard/billing/credit_grants';
      case ProviderType.anthropic:
        return '/v1/organizations/{id}/usage';
      case ProviderType.deepseek:
        return '/user/balance';
      case ProviderType.openrouter:
        return '/v1/credits';
      case ProviderType.groq:
        return '/openai/v1/models';
      case ProviderType.together:
        return '/v1/billing/cost_details';
      case ProviderType.siliconflow:
        return '/v1/user/info';
      case ProviderType.moonshot:
        return '/v1/users/me/balance';
      case ProviderType.qwen:
        return '/v1/models';
      case ProviderType.minimax:
        return '/anthropic/v1/models';
      default:
        return '/v1/models';
    }
  }
}

/// Bottom sheet showing a provider's available models.
class _ModelsSheet extends StatelessWidget {
  final List<ModelInfo> models;
  final String providerName;

  const _ModelsSheet({required this.models, required this.providerName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.model_training_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$providerName Models',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${models.length} models',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: models.length,
              itemBuilder: (ctx, i) => _ModelTile(model: models[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final ModelInfo model;

  const _ModelTile({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPricing =
        model.inputPricePer1M != null || model.outputPricePer1M != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (model.capabilities != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      model.capabilities!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (hasPricing) ...[
                  Icon(Icons.attach_money_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      model.priceDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (model.contextWindow != null) ...[
                  if (hasPricing) const SizedBox(width: 12),
                  Icon(Icons.aspect_ratio_rounded,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    model.contextDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (model.id != model.displayName) ...[
              const SizedBox(height: 4),
              Text(
                model.id,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
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
      );
  }
}

class _BalanceChart extends StatelessWidget {
  final List<BalanceSnapshot> snapshots;
  final String currency;
  final bool loading;

  const _BalanceChart({
    required this.snapshots,
    required this.currency,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Balance History',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshots.length < 2)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Not enough data yet.\nRefresh balances over time to build history.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: _buildChart(colorScheme),
              ),
          ],
        ),
      );
  }

  Widget _buildChart(ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < snapshots.length; i++) {
      spots.add(FlSpot(i.toDouble(), snapshots[i].balance));
    }

    final minY = snapshots.map((s) => s.balance).reduce(
          (a, b) => a < b ? a : b,
        );
    final maxY = snapshots.map((s) => s.balance).reduce(
          (a, b) => a > b ? a : b,
        );
    final yPadding = (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minY: (minY - yPadding).clamp(0, double.infinity),
        maxY: maxY + yPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _niceInterval(minY, maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _bottomInterval,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= snapshots.length) {
                  return const SizedBox.shrink();
                }
                final date = snapshots[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final date = idx >= 0 && idx < snapshots.length
                    ? DateFormat('MMM d').format(snapshots[idx].date)
                    : '';
                return LineTooltipItem(
                  '$date\n\$${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: snapshots.length <= 14,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: colorScheme.primary,
                strokeWidth: 1.5,
                strokeColor: colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  double _niceInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    if (range <= 100) return 20;
    return (range / 4).ceilToDouble();
  }

  double get _bottomInterval {
    if (snapshots.length <= 7) return 1;
    if (snapshots.length <= 14) return 2;
    if (snapshots.length <= 31) return 7;
    return 14;
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? colorScheme.onPrimaryContainer : null,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
