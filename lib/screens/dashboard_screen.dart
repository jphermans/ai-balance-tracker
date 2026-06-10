import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../models/balance_info.dart';
import '../models/provider_config.dart';
import '../widgets/provider_card.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  bool _initialRefreshDone = false;
  final _refreshingIds = <String>{};
  ProviderSubscription<dynamic>? _providersSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefreshIfReady();
    });
  }

  @override
  void dispose() {
    _providersSubscription?.close();
    super.dispose();
  }

  void _autoRefreshIfReady() {
    if (_initialRefreshDone) return;
    final configs = ref.read(providersProvider);
    if (configs.isNotEmpty) {
      _initialRefreshDone = true;
      _refresh();
    } else {
      _providersSubscription = ref.listenManual(providersProvider, (prev, next) {
        if (!_initialRefreshDone && next != null && next.isNotEmpty) {
          _initialRefreshDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
        }
      });
    }
  }

  Future<void> _refresh() async {
    final configs = ref.read(providersProvider);
    if (configs.isNotEmpty) {
      await ref.read(balancesProvider.notifier).refreshAll(configs);
    }
  }

  Future<void> _refreshOne(ProviderConfig config) async {
    setState(() => _refreshingIds.add(config.id));
    try {
      await ref.read(balancesProvider.notifier).refreshOne(config);
    } finally {
      if (mounted) setState(() => _refreshingIds.remove(config.id));
    }
  }

  List<MapEntry<String, BalanceInfo>> _filteredBalances(
    Map<String, BalanceInfo> balances,
  ) {
    var entries = balances.entries.toList();
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      entries = entries
          .where((e) => e.value.providerName.toLowerCase().contains(query))
          .toList();
    }
    // Sort: active first, then alphabetical
    entries.sort((a, b) {
      final aActive = a.value.status == BalanceStatus.active ? 0 : 1;
      final bActive = b.value.status == BalanceStatus.active ? 0 : 1;
      if (aActive != bActive) return aActive.compareTo(bActive);
      return a.value.providerName.compareTo(b.value.providerName);
    });
    return entries;
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(balancesProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final providers = ref.watch(providersProvider);
    final lastRefreshed = ref.watch(lastRefreshedProvider);
    final theme = Theme.of(context);

    final filtered = _filteredBalances(balances);
    final totalBalance = filtered
        .where((e) => e.value.status == BalanceStatus.active)
        .fold<double>(0, (sum, e) => sum + e.value.balance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Balance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => context.push('/about'),
            tooltip: 'About',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _refresh,
            tooltip: 'Refresh all',
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (isOffline)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.cloud_off_rounded, color: Colors.white),
              backgroundColor: Colors.orange.shade700,
              content: const Text(
                'You are offline — balances shown may be out of date.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: _refresh,
                  child: const Text('RETRY',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SearchBar(
                        hintText: 'Search providers...',
                        leading: const Icon(Icons.search_rounded),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                  ),
                  // Total balance header
                  if (filtered.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              Text(
                                'Total Balance',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${totalBalance.toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${filtered.length} providers',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Last refreshed timestamp (Issue #41)
                  if (lastRefreshed != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Center(
                          child: Text(
                            'Last refreshed ${_formatTimestamp(lastRefreshed!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Provider cards
                  if (filtered.isEmpty && !isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              providers.isEmpty
                                  ? 'No providers configured'
                                  : 'No matching providers',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (providers.isEmpty)
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push('/add-provider'),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Provider'),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = filtered[index];
                            final config = providers.firstWhere(
                              (p) => p.id == entry.key,
                              orElse: () => providers.first,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProviderCard(
                                info: entry.value,
                                onDetailTap: () =>
                                    context.push('/provider/${entry.key}'),
                                onRefresh: () => _refreshOne(config),
                                refreshing: _refreshingIds.contains(entry.key),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-provider'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Provider'),
      ),
    );
  }
}
