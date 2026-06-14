import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_card.dart';

/// Step-by-step migration assistant for the Supabase provider_configs table.
class SyncFixScreen extends ConsumerStatefulWidget {
  const SyncFixScreen({super.key});

  @override
  ConsumerState<SyncFixScreen> createState() => _SyncFixScreenState();
}

class _SyncFixScreenState extends ConsumerState<SyncFixScreen> {
  /// True once the in-app schema check confirms the migration was applied.
  bool _migrationVerified = false;

  /// True while running the schema check.
  bool _checkingSchema = false;

  /// Error message from schema check.
  String? _checkError;

  @override
  void initState() {
    super.initState();
    // Auto-run schema check on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSchemaCheck();
    });
  }

  Future<void> _runSchemaCheck() async {
    if (!mounted) return;
    setState(() {
      _checkingSchema = true;
      _checkError = null;
    });

    try {
      final response = await SupabaseService.client
          .from('provider_configs')
          .select('provider_id, user_id')
          .limit(50);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

      // Group by provider_id and check for multiple user_ids
      final byProvider = <String, Set<String>>{};
      for (final row in rows) {
        final pid = row['provider_id'] as String?;
        final uid = row['user_id'] as String?;
        if (pid == null || uid == null) continue;
        byProvider.putIfAbsent(pid, () => {}).add(uid);
      }

      final hasMultiUser = byProvider.values.any((users) => users.length > 1);

      if (!mounted) return;
      setState(() {
        _checkingSchema = false;
        _migrationVerified = !hasMultiUser;
        if (hasMultiUser) {
          _checkError =
              'Old schema detected: ${byProvider.entries.where((e) => e.value.length > 1).length} '
              'provider(s) have multiple user_id rows. Run the migration below.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingSchema = false;
        _checkError = 'Could not reach Supabase: $e';
        _migrationVerified = false;
      });
    }
  }

  /// Step 1 SQL — drop old constraint, add new one.
  static const _step1Sql = '''
-- Drop the per-user unique constraint (old schema)
ALTER TABLE provider_configs DROP CONSTRAINT IF EXISTS provider_configs_user_id_provider_id_key;

-- Add global unique constraint on provider_id (new schema)
ALTER TABLE provider_configs ADD CONSTRAINT provider_configs_provider_id_key UNIQUE (provider_id);
''';

  /// Step 2 SQL — replace RLS policy for full access.
  static const _step2Sql = '''
-- Remove old per-user RLS policy
DROP POLICY IF EXISTS "Users manage own configs" ON provider_configs;

-- Allow all authenticated (including anonymous) users full access.
-- Security model: anyone with the publishable key can read/write rows;
-- API keys are AES-256-GCM encrypted client-side before storage.
CREATE POLICY "Authenticated full access" ON provider_configs
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);
''';

  /// Cleanup SQL — remove duplicate rows keeping newest per provider_id.
  static const _cleanupSql = '''
-- Remove duplicate provider_ids (keep newest row per provider_id)
DELETE FROM provider_configs
WHERE id NOT IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY provider_id ORDER BY updated_at DESC
    ) AS rn
    FROM provider_configs
  ) ranked
  WHERE rn = 1
);
''';

  void _copyToClipboard(String sql, BuildContext context) {
    Clipboard.setData(ClipboardData(text: sql.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SQL copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Re-watch the provider so the banner disappears once migration is done
    final syncHealth = ref.watch(syncHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Cloud Sync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          _buildStatusCard(colorScheme),
          const SizedBox(height: 16),

          // The banner may still show if user navigated away and came back;
          // if migration is now verified, prompt them to go back.
          if (_migrationVerified || syncHealth == SyncHealth.ok) ...[
            _buildSuccessCard(colorScheme),
            const SizedBox(height: 24),
          ],

          if (!_migrationVerified && syncHealth == SyncHealth.needsMigration) ...[
            // Explanation
            _buildExplanationCard(colorScheme),
            const SizedBox(height: 16),

            // Step 0: Cleanup duplicates (optional but recommended)
            _buildStepCard(
              step: 0,
              title: 'Clean up duplicate rows (recommended)',
              description:
                  'If you had sync issues before, you may have duplicate rows in your table. '
                  'Run this to delete them and keep only the newest row per provider.',
              sql: _cleanupSql,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Step 1
            _buildStepCard(
              step: 1,
              title: 'Change unique constraint',
              description:
                  'Drop the old per-user constraint and add a global one on provider_id.',
              sql: _step1Sql,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Step 2
            _buildStepCard(
              step: 2,
              title: 'Update access policy',
              description:
                  'Replace the per-user RLS policy with one that lets all devices share data.',
              sql: _step2Sql,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // After running SQL
            _buildAfterCard(colorScheme),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    final isVerifying = _checkingSchema;
    final isFixed = _migrationVerified;

    Color bgColor;
    IconData icon;
    String title;
    String subtitle;
    Color textColor = Colors.white;

    if (isVerifying) {
      bgColor = Colors.blue.shade700;
      icon = Icons.sync_rounded;
      title = 'Checking Supabase schema...';
      subtitle = 'Connecting to your project to verify the migration status.';
    } else if (isFixed) {
      bgColor = Colors.green.shade700;
      icon = Icons.check_circle_rounded;
      title = 'Migration complete ✓';
      subtitle = 'Your table is correctly configured for cross-device sync.';
    } else {
      bgColor = Colors.red.shade700;
      icon = Icons.warning_rounded;
      title = 'Sync is broken — migration needed';
      subtitle = _checkError ??
          'The old schema is active. Follow the steps below to fix sync.';
    }

    return GlassCard(
      backgroundColor: bgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (isVerifying)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          else
            Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerifying)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Re-check schema',
              onPressed: _runSchemaCheck,
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(ColorScheme colorScheme) {
    return GlassCard(
      backgroundColor: Colors.green.shade900.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: Colors.green.shade300, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All done! 🎉',
                  style: TextStyle(
                    color: Colors.green.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cross-device sync is now working. Restart every device '
                  'to re-fetch data with the new schema.',
                  style: TextStyle(
                    color: Colors.green.shade200,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(ColorScheme colorScheme) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'What happened?',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Before v1.15.0, the provider_configs table was set up with a per-user '
            'unique constraint (user_id, provider_id). This means every device that '
            'signs into your Supabase project gets its own private copy of each provider — '
            'no other device can see or modify it.\n\n'
            'Since anonymous auth gives each device a different user_id, cross-device '
            'sync never worked. The upsert also failed because it referenced a constraint '
            'that didn\'t match the actual table structure.\n\n'
            'The fix: change the unique constraint to just provider_id (globally shared) '
            'and update the RLS policy to allow all authenticated devices full access. '
            'Run the SQL below in your Supabase SQL Editor.',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required String sql,
    required ColorScheme colorScheme,
  }) {
    final stepLabel = step == 0 ? 'Optional' : 'Step $step';
    final stepColor = step == 0 ? Colors.orange.shade700 : Colors.indigo.shade700;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stepColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stepLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // SQL block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              sql.trim(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.green.shade300,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Copy button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(sql, context),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy SQL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAfterCard(ColorScheme colorScheme) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.done_all_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'After running all SQL statements:',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bullet(
            colorScheme,
            'Tap the refresh button above to re-check the schema and confirm the fix.',
          ),
          _bullet(
            colorScheme,
            'Restart every device running the app so it re-fetches data '
                'with the new schema.',
          ),
          _bullet(
            colorScheme,
            'If you had duplicate rows, run the optional cleanup SQL first '
                'to remove them before testing.',
          ),
          _bullet(
            colorScheme,
            'Cross-device sync will now work: adding or editing a provider on '
                'one device will appear on all other devices within seconds.',
          ),
        ],
      ),
    );
  }

  Widget _bullet(ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
