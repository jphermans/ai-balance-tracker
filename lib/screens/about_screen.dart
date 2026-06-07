import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen with app info, tech stack, credits, and links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _repoUrl = 'https://github.com/jphermans/ai-balance-tracker';
  static const _version = '1.5.0';
  static const _buildNumber = '9';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── App Header ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                // App icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Balance Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version $_version (build $_buildNumber)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Description ─────────────────────────────────────────
          _SectionHeader(title: 'About', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'AI Balance Tracker securely monitors credits, usage, and '
                'funds across all your AI providers in a unified dashboard. '
                'Keep track of 19+ API providers with real-time balance '
                'queries, optional PIN protection, and keychain-secured '
                'credentials.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Tech Stack ──────────────────────────────────────────
          _SectionHeader(title: 'Tech Stack', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _TechItem(
                  icon: Icons.flutter_dash_rounded,
                  label: 'Framework',
                  value: 'Flutter 3.38+',
                ),
                _Divider(),
                _TechItem(
                  icon: Icons.layers_rounded,
                  label: 'State Management',
                  value: 'Riverpod',
                ),
                _Divider(),
                _TechItem(
                  icon: Icons.route_rounded,
                  label: 'Navigation',
                  value: 'GoRouter',
                ),
                _Divider(),
                _TechItem(
                  icon: Icons.security_rounded,
                  label: 'Credential Storage',
                  value: 'iOS Keychain (flutter_secure_storage)',
                ),
                _Divider(),
                _TechItem(
                  icon: Icons.design_services_rounded,
                  label: 'Design System',
                  value: 'Material 3 (iOS-inspired theme)',
                ),
                _Divider(),
                _TechItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Charts',
                  value: 'fl_chart',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Features ────────────────────────────────────────────
          _SectionHeader(title: 'Features', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FeatureBullet(theme, 'Unified dashboard for 19+ AI providers'),
                  _FeatureBullet(theme, 'Real-time balance queries for 7 providers'),
                  _FeatureBullet(theme, 'Optional 4-digit PIN lock'),
                  _FeatureBullet(theme, 'iOS Keychain-backed secure storage'),
                  _FeatureBullet(theme, 'Dark/light/system theme support'),
                  _FeatureBullet(theme, 'Custom app icon and splash screen'),
                  _FeatureBullet(theme, 'Unsigned IPA builder via GitHub Actions'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Links ───────────────────────────────────────────────
          _SectionHeader(title: 'Links', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Source Code'),
                  subtitle: const Text(
                    'github.com/jphermans/ai-balance-tracker',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl(_repoUrl),
                ),
                _Divider(),
                ListTile(
                  leading: Icon(
                    Icons.bug_report_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Report an Issue'),
                  subtitle: const Text(
                    'GitHub Issues',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl('$_repoUrl/issues'),
                ),
                _Divider(),
                ListTile(
                  leading: Icon(
                    Icons.download_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Download IPA'),
                  subtitle: const Text(
                    'GitHub Actions artifacts',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl('$_repoUrl/actions/workflows/build-ipa.yml'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── License ─────────────────────────────────────────────
          _SectionHeader(title: 'License', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'MIT License — Free to use, modify, and distribute.\n'
                '© JPHsystems',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ── Footer ──────────────────────────────────────────────
          Center(
            child: Text(
              'Made with ❤️ by JPHsystems',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _TechItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.4),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final ThemeData theme;
  final String text;

  const _FeatureBullet(this.theme, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
