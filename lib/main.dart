import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.initialize();
  runApp(const ProviderScope(child: AIBalanceApp()));
}
