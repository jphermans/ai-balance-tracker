import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import 'pin_service.dart';

/// Detects fresh installs and clears stale Keychain data.
/// iOS Keychain survives app deletion, so on first launch after reinstall,
/// we clear old credentials and PIN to give a clean slate.
class FirstLaunchService {
  static const _launchedKey = 'has_launched_before';

  /// Call once at app startup. Returns true if this was a fresh install.
  static Future<bool> handleFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool(_launchedKey) ?? false;

    if (!hasLaunched) {
      // Fresh install — clear any stale Keychain data from a previous install
      await SecureStorageService.deleteAll();
      await PinService.removePin();
      await prefs.setBool(_launchedKey, true);
      return true;
    }
    return false;
  }
}
