import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../models/provider_config.dart';
import '../services/pin_service.dart';
import '../services/supabase_config_service.dart';
import '../services/supabase_service.dart';
import 'add_provider_screen.dart';
import '../services/export_service.dart';
import '../widgets/glass_card.dart';
import '../app_version.dart';
import '../utils/app_reload.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final hasPin = ref.watch(pinProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          GlassSectionLabel('APPEARANCE'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
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
          ),
          const SizedBox(height: 24),

          // Security
          if (!kIsWeb) ...[
            GlassSectionLabel('SECURITY'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: hasPin ? theme.colorScheme.primary : null,
                ),
                title: const Text('PIN Lock'),
                subtitle: Text(hasPin ? 'Enabled' : 'Not set'),
                trailing: hasPin
                    ? TextButton(
                        onPressed: () => _confirmRemovePin(context, ref),
                        child: Text(
                          'Remove',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    : FilledButton.tonal(
                        onPressed: () => context.push('/pin-setup'),
                        child: const Text('Set PIN'),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Cloud Sync
          const _CloudSyncSection(),
          const SizedBox(height: 24),

          // Configured Providers
          GlassSectionLabel('CONFIGURED PROVIDERS'),
          if (providers.isEmpty)
            GlassCard(
              child: Center(
                child: Text(
                  'No providers configured yet.\n'
                  'Tap + on the dashboard to add one.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...providers.map((config) => _ProviderTile(config: config)),
          const SizedBox(height: 24),

          // Data
          GlassSectionLabel('DATA'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export as CSV'),
                  subtitle: const Text('Share all balances as spreadsheet'),
                  onTap: () => _exportCsv(context, ref),
                ),
                const Divider(height: 1),
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
          GlassSectionLabel('ABOUT'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('AI Balance Tracker'),
              subtitle: Text('Version $appVersion'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/about'),
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

  void _exportCsv(BuildContext context, WidgetRef ref) async {
    final balances = ref.read(balancesProvider);
    if (balances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await ExportService.exportBalances(balances);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmRemovePin(BuildContext context, WidgetRef ref) {
    _showRemovePinDialog(context, ref);
  }

  void _showRemovePinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Remove PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your current PIN to remove it.'),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() => error = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final pin = pinController.text;
                  if (pin.length != 4) {
                    setDialogState(() => error = 'PIN must be 4 digits');
                    return;
                  }
                  final result = await PinService.verifyPin(pin);
                  if (!ctx.mounted) return;
                  switch (result) {
                    case PinVerifyResult.success:
                      await ref.read(pinProvider.notifier).removePin();
                      if (ctx.mounted) Navigator.pop(ctx);
                    case PinVerifyResult.wrong:
                      setDialogState(() => error = 'Incorrect PIN');
                    case PinVerifyResult.locked:
                      final remaining = await PinService.lockoutRemaining();
                      if (!ctx.mounted) return;
                      setDialogState(() => error =
                          'Too many attempts. Try again in ${remaining.inSeconds}s.');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remove PIN'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Supabase cloud sync configuration section with URL + anon key fields.
class _CloudSyncSection extends StatefulWidget {
  const _CloudSyncSection();

  @override
  State<_CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends State<_CloudSyncSection> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _showKey = false;
  bool _saving = false;
  bool _clearing = false;
  String? _statusText;
  bool _connected = false;
  String? _savedUrl;
  String? _savedKey;

  bool get _fieldsUnchanged =>
      _urlController.text.trim() == (_savedUrl ?? '') &&
      _keyController.text.trim() == (_savedKey ?? '');

  bool get _canSave =>
      !_connected &&
      !_fieldsUnchanged &&
      _urlController.text.trim().isNotEmpty &&
      _keyController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final (url, key) = await SupabaseConfigService.loadConfig();
    if (url != null && mounted) {
      _savedUrl = url;
      _savedKey = key ?? '';
      _urlController.text = url;
      _keyController.text = key ?? '';
      setState(() {
        _connected = SupabaseService.isInitialized;
        _statusText = _connected
            ? 'Connected'
            : kIsWeb ? 'Saved — reload page to connect' : 'Saved — restart app to connect';
      });
    } else {
      setState(() {
        _statusText = 'Not configured';
      });
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isEmpty || key.isEmpty) return;
    if (_connected && _fieldsUnchanged) return; // nothing to do

    setState(() => _saving = true);
    try {
      await SupabaseConfigService.saveConfig(url: url, anonKey: key);
      _savedUrl = url;
      _savedKey = key;

      if (_connected) {
        // Already connected — just updated saved config
        _showReloadDialog(kIsWeb
            ? 'Supabase config updated. Reload page to apply?'
            : 'Supabase config updated. Restart to apply changes.');
      } else {
        setState(() {
          _statusText = kIsWeb
              ? 'Saved — reload page to connect'
              : 'Saved — restart app to connect';
        });
        _showReloadDialog(kIsWeb
            ? 'Config saved! Reload page to connect?'
            : 'Saved. Restart the app to connect.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Supabase Config?'),
        content: Text(kIsWeb
            ? 'This will disconnect cloud sync. Your provider data stays on this device.\n\nReload the page after removing to apply the change.'
            : 'This will disconnect cloud sync. Your provider data stays on this device.\n\nRestart the app after removing to apply the change.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);
    try {
      await SupabaseConfigService.clearConfig();
      _urlController.clear();
      _keyController.clear();
      setState(() {
        _connected = false;
        _statusText = kIsWeb ? 'Removed — reload page' : 'Removed — restart app';
      });
      _showReloadDialog(kIsWeb
          ? 'Supabase config removed. Reload page to apply?'
          : 'Supabase config removed. Restart to apply.');
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _showReloadDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud Sync'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          if (kIsWeb)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                reloadApp();
              },
              child: const Text('Reload Now'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasConfig = _urlController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionLabel('CLOUD SYNC'),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Row(
                children: [
                  Icon(
                    _connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    size: 18,
                    color: _connected ? Colors.green : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Supabase',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_statusText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _connected
                            ? Colors.green.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _connected
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // URL field
              TextField(
                controller: _urlController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Project URL',
                  hintText: 'https://xxxxxxxxxxxx.supabase.co',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Anon key field
              TextField(
                controller: _keyController,
                onChanged: (_) => setState(() {}),
                obscureText: !_showKey,
                decoration: InputDecoration(
                  labelText: 'Publishable Key',
                  hintText: 'sb_publishable_... (or anon key)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showKey = !_showKey),
                  ),
                ),
                autocorrect: false,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_saving || !_canSave) ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                  ),
                  if (hasConfig) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _clearing ? null : _clear,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  final ProviderConfig config;
  const _ProviderTile({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AddProviderScreen(existingConfig: config),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
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
