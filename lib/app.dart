import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_provider_screen.dart';
import 'models/provider_config.dart';
import 'screens/pin_unlock_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/about_screen.dart';
import 'widgets/splash_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/provider/:id',
        name: 'provider-detail',
        builder: (context, state) => ProviderDetailScreen(
          providerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/add-provider',
        name: 'add-provider',
        builder: (context, state) => AddProviderScreen(
          existingConfig: state.extra as ProviderConfig?,
        ),
      ),
      GoRoute(
        path: '/pin-setup',
        name: 'pin-setup',
        builder: (context, state) =>
            const PinSetupScreen(isOnboarding: false),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});

class AIBalanceApp extends ConsumerStatefulWidget {
  const AIBalanceApp({super.key});

  @override
  ConsumerState<AIBalanceApp> createState() => _AIBalanceAppState();
}

class _AIBalanceAppState extends ConsumerState<AIBalanceApp> {
  bool _showSplash = true;
  bool _unlocked = false;
  bool _pinSet = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final hasPin = ref.watch(pinProvider);

    // Show branded splash screen first
    if (_showSplash) {
      return MaterialApp(
        title: 'AI Balance Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: SplashScreen(
          onDone: () => setState(() => _showSplash = false),
        ),
      );
    }

    // After splash: PIN lock (skip on web — no secure storage)
    if (!kIsWeb) {
      if (!hasPin && !_pinSet) {
        return MaterialApp(
          title: 'AI Balance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: PinSetupScreen(
            isOnboarding: true,
            onSkip: () => setState(() => _pinSet = true),
            key: ValueKey('onboarding-pin-$_pinSet'),
          ),
        );
      }

      if (hasPin && !_unlocked) {
        return MaterialApp(
          title: 'AI Balance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: PinUnlockScreen(
            onUnlocked: () => setState(() => _unlocked = true),
          ),
        );
      }
    }

    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'AI Balance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
