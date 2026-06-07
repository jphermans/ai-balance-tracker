import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/secure_storage_service.dart';
import 'services/first_launch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.initialize();
  // Clear stale Keychain data on fresh install after app deletion
  await FirstLaunchService.handleFirstLaunch();
  runApp(const ProviderScope(child: AIBalanceApp()));
}
