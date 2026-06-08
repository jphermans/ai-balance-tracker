import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/secure_storage_service.dart';
import 'services/first_launch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Keychain access can hang on macOS if sandboxed or unsigned.
  // Wrap in timeout so the app always launches.
  try {
    await SecureStorageService.initialize().timeout(
      const Duration(seconds: 2),
    );
  } catch (_) {
    // Keychain unavailable — app will start with empty state
  }
  
  // Clear stale Keychain data on fresh install after app deletion
  try {
    await FirstLaunchService.handleFirstLaunch().timeout(
      const Duration(seconds: 2),
    );
  } catch (_) {
    // Non-critical — skip on failure
  }
  runApp(const ProviderScope(child: AIBalanceApp()));
}
