import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../models/provider_config.dart';

class AddProviderScreen extends ConsumerStatefulWidget {
  /// Optional existing config for editing mode.
  final ProviderConfig? existingConfig;

  const AddProviderScreen({super.key, this.existingConfig});

  @override
  ConsumerState<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends ConsumerState<AddProviderScreen> {
  ProviderType? _selectedType;
  final _keyController = TextEditingController();
  final _orgController = TextEditingController();
  final _accountController = TextEditingController();
  final _endpointController = TextEditingController();
  String _searchQuery = '';
  bool _showKey = false;
  bool _saving = false;

  List<ProviderType> get _filteredTypes {
    if (_searchQuery.isEmpty) return ProviderType.values.toList();
    final query = _searchQuery.toLowerCase();
    return ProviderType.values
        .where((t) => t.displayName.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _orgController.dispose();
    _accountController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingConfig != null;
  ProviderConfig? get _existing => widget.existingConfig;

  @override
  void initState() {
    super.initState();
    if (_existing != null) {
      _selectedType = _existing!.type;
      _keyController.text = _existing!.apiKey;
      _orgController.text = _existing!.orgId ?? '';
      _accountController.text = _existing!.accountId ?? '';
      _endpointController.text = _existing!.customEndpoint ?? '';
    }
  }

  bool get _canSave =>
      _selectedType != null && _keyController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _saving = true);
    try {
      final config = ProviderConfig(
        id: '${_selectedType!.name}_${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType!,
        apiKey: _keyController.text.trim(),
        orgId: _orgController.text.trim().isEmpty
            ? null
            : _orgController.text.trim(),
        accountId: _accountController.text.trim().isEmpty
            ? null
            : _accountController.text.trim(),
        customEndpoint: _endpointController.text.trim().isEmpty
            ? null
            : _endpointController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(providersProvider.notifier).updateProvider(config);
      } else {
        await ref.read(providersProvider.notifier).addProvider(config);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '${_selectedType!.displayName} updated'
                : '${_selectedType!.displayName} added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? _existing!.type.displayName : 'Add Provider'),
        actions: [
          FilledButton(
            onPressed: _canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider selection
          Text(
            'SELECT PROVIDER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SearchBar(
            hintText: 'Search providers...',
            leading: const Icon(Icons.search_rounded),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filteredTypes.map((type) {
              final selected = _selectedType == type;
              return FilterChip(
                label: Text(type.displayName),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
                avatar: selected
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // API Key
          if (_selectedType != null) ...[
            Text(
              'CREDENTIALS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _keyController,
                      obscureText: !_showKey,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'sk-...',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showKey
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _showKey = !_showKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _orgController,
                      decoration: const InputDecoration(
                        labelText: 'Organization ID (optional)',
                        hintText: 'org-...',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accountController,
                      decoration: const InputDecoration(
                        labelText: 'Account ID (optional)',
                        hintText: 'acc_...',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endpointController,
                      decoration: InputDecoration(
                        labelText: 'Custom Endpoint (optional)',
                        hintText: _selectedType!.baseUrl,
                        prefixIcon:
                            const Icon(Icons.link_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedType!.hasBalanceEndpoint
                            ? '${_selectedType!.displayName} supports full balance checking.'
                            : '${_selectedType!.displayName} does not expose balance via API. Only key validation is available.',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
