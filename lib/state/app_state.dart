import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/balance_info.dart';
import '../models/provider_config.dart';
import '../services/hybrid_storage_service.dart';
import '../services/supabase_service.dart';
import '../services/balance_service.dart';
import '../services/history_service.dart';
import '../services/pin_service.dart';
import '../services/widget_data_service.dart';

/// Manages the list of configured providers.
class ProvidersNotifier extends StateNotifier<List<ProviderConfig>> {
  ProvidersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await HybridStorageService.loadProviders();
    // Start listening for realtime cloud changes
    if (SupabaseService.isInitialized) {
      HybridStorageService.startRealtimeSync((providers) {
        state = providers;
      });
    }
  }

  Future<void> addProvider(ProviderConfig config) async {
    await HybridStorageService.saveProvider(config);
    state = await HybridStorageService.loadProviders();
  }

  Future<void> updateProvider(ProviderConfig config) async {
    await HybridStorageService.saveProvider(config);
    state = await HybridStorageService.loadProviders();
  }

  Future<void> removeProvider(String id) async {
    await HybridStorageService.removeProvider(id);
    state = await HybridStorageService.loadProviders();
  }

  Future<void> toggleProvider(String id, bool enabled) async {
    final providers = await HybridStorageService.loadProviders();
    final index = providers.indexWhere((p) => p.id == id);
    if (index >= 0) {
      providers[index] = providers[index].copyWith(enabled: enabled);
      await HybridStorageService.saveProviders(providers);
      state = providers;
    }
  }

  Future<void> clearAll() async {
    await HybridStorageService.deleteAll();
    state = [];
  }
}

/// Manages balance data for all providers.
class BalancesNotifier extends StateNotifier<Map<String, BalanceInfo>> {
  BalancesNotifier() : super({});

  bool _loading = false;
  DateTime? lastRefreshedAt;

  bool get isLoading => _loading;

  Future<void> refreshAll(List<ProviderConfig> configs) async {
    if (_loading) return;
    _loading = true;
    try {
      final balances = await BalanceService.fetchAllBalances(configs);
      final map = <String, BalanceInfo>{};
      for (final b in balances) {
        map[b.providerId] = b;
        if (b.supportsBalance) {
          HistoryService.recordSnapshot(
            providerId: b.providerId,
            balance: b.balance,
          );
        }
      }
      state = map;
      lastRefreshedAt = DateTime.now();
      WidgetDataService.updateFromBalances(map);
    } finally {
      _loading = false;
    }
  }

  Future<void> refreshOne(ProviderConfig config) async {
    final balance = await BalanceService.refreshProvider(config);
    final newState = {...state, balance.providerId: balance};
    state = newState;
    lastRefreshedAt = DateTime.now();
    WidgetDataService.updateFromBalances(newState);
    if (balance.supportsBalance) {
      HistoryService.recordSnapshot(
        providerId: balance.providerId,
        balance: balance.balance,
      );
    }
  }
}

/// Manages the app theme mode.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode mode) => state = mode;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

// Providers
final providersProvider =
    StateNotifierProvider<ProvidersNotifier, List<ProviderConfig>>((ref) {
  return ProvidersNotifier();
});

final balancesProvider =
    StateNotifierProvider<BalancesNotifier, Map<String, BalanceInfo>>((ref) {
  return BalancesNotifier();
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Manages whether a PIN lock is active.
class PinNotifier extends StateNotifier<bool> {
  PinNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await PinService.hasPin();
  }

  Future<void> refresh() async {
    state = await PinService.hasPin();
  }

  Future<void> setPin(String pin) async {
    await PinService.setPin(pin);
    state = true;
  }

  Future<void> removePin() async {
    await PinService.removePin();
    state = false;
  }
}

final pinProvider = StateNotifierProvider<PinNotifier, bool>((ref) {
  return PinNotifier();
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(balancesProvider.notifier).isLoading;
});

final lastRefreshedProvider = Provider<DateTime?>((ref) {
  return ref.watch(balancesProvider).isEmpty
      ? null
      : ref.read(balancesProvider.notifier).lastRefreshedAt;
});

/// Tracks whether the device currently has network connectivity.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Derived: true when the device has NO network connection.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) => results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none),
    loading: () => false, // assume online while checking
    error: (_, _) => false,
  );
});
