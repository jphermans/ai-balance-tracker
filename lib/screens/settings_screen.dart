import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../models/provider_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: const Text('Theme'),
                  subtitle: Text(themeMode.name),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_iphone_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (set) {
                      ref.read(themeModeProvider.notifier).setTheme(set.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Configured Providers
          Text(
            'CONFIGURED PROVIDERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          if (providers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No providers configured yet.\nTap + on the dashboard to add one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...providers.map((config) => _ProviderTile(config: config)),
          const SizedBox(height: 24),

          // Data
          Text(
            'DATA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Remove all providers and credentials'),
                  textColor: theme.colorScheme.error,
                  iconColor: theme.colorScheme.error,
                  onTap: () => _confirmClearAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text(
            'ABOUT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('AI Balance Tracker'),
                  subtitle: Text('Version 1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all configured providers and their API keys. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(providersProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  final ProviderConfig config;
  const _ProviderTile({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  config.type.displayName.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(config.type.displayName),
            subtitle: Text('API Key: ${_maskKey(config.apiKey)}'),
            value: config.enabled,
            onChanged: (enabled) {
              ref
                  .read(providersProvider.notifier)
                  .toggleProvider(config.id, enabled);
            },
          ),
          OverflowBar(
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(providersProvider.notifier).removeProvider(config.id);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }
}
