# AI Balance Tracker

> Securely monitor credits, usage, and funds across all your AI providers in a unified dashboard.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-16.0+-000000?logo=apple)](https://apple.com/ios)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
  <img src="assets/screenshots/dashboard.png" width="250" alt="Dashboard">
  <img src="assets/screenshots/detail.png" width="250" alt="Provider Detail">
  <img src="assets/screenshots/settings.png" width="250" alt="Settings">
</p>

## Features

- **Unified Dashboard** — View balances from all your AI providers at a glance
- **19 Providers Supported** — OpenAI, Anthropic, DeepSeek, OpenRouter, Google AI, xAI, Groq, Together AI, and more
- **Secure Storage** — API keys stored in iOS Keychain / Android EncryptedSharedPreferences, never in plain text
- **Dark & Light Mode** — Material 3 with automatic theme adaptation
- **Provider Adapters** — Clean architecture: add new providers by implementing `AIProvider`
- **Balance History** — Track spending and credits over time (coming soon)
- **Offline Support** — Cached balances available when you're offline
- **CSV Export** — Export your balance data for external analysis
- **Developer Mode** — View raw API responses for debugging

## Supported Providers

| Provider | Balance API | Key Validation |
|----------|:-----------:|:--------------:|
| OpenAI | ✅ | ✅ |
| Anthropic | ✅ | ✅ |
| DeepSeek | ✅ | ✅ |
| OpenRouter | ✅ | ✅ |
| Together AI | ✅ | ✅ |
| Groq | ⚠️ | ✅ |
| Google AI Studio | ❌ | ✅ |
| xAI | ❌ | ✅ |
| Cohere | ❌ | ✅ |
| Mistral AI | ❌ | ✅ |
| Fireworks AI | ❌ | ✅ |
| Perplexity | ❌ | ✅ |
| Novita AI | ❌ | ✅ |
| SiliconFlow | ❌ | ✅ |
| Moonshot AI | ❌ | ✅ |
| Cerebras | ❌ | ✅ |
| Replicate | ❌ | ✅ |
| Hugging Face | ❌ | ✅ |
| SambaNova | ❌ | ✅ |
| AI21 Labs | ❌ | ✅ |

✅ Full balance tracking &nbsp; ⚠️ Key validation only &nbsp; ❌ Key validation only

## Architecture

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp + routing
├── models/
│   ├── balance_info.dart  # Balance data model
│   ├── usage_info.dart    # Usage statistics model
│   └── provider_config.dart # Provider configuration + types
├── providers/
│   ├── ai_provider.dart   # Abstract base class
│   ├── openai_provider.dart
│   ├── anthropic_provider.dart
│   ├── deepseek_provider.dart
│   ├── openrouter_provider.dart
│   ├── groq_provider.dart
│   ├── together_provider.dart
│   ├── stub_provider.dart # For providers without balance APIs
│   └── provider_registry.dart
├── services/
│   ├── secure_storage_service.dart  # Keychain-backed storage
│   └── balance_service.dart         # Balance fetching orchestration
├── state/
│   └── app_state.dart     # Riverpod state management
├── theme/
│   └── app_theme.dart     # Material 3 light/dark themes
├── screens/
│   ├── dashboard_screen.dart
│   ├── provider_detail_screen.dart
│   ├── settings_screen.dart
│   └── add_provider_screen.dart
└── widgets/
    └── provider_card.dart
```

### Adding a New Provider

1. Create a new class in `lib/providers/` that extends `AIProvider`
2. Implement `getBalance()` and `getUsage()`
3. Add the provider type to `ProviderType` enum in `provider_config.dart`
4. Register it in `ProviderRegistry.create()`

```dart
class MyProvider extends AIProvider {
  MyProvider(super.config);

  @override
  Map<String, String> get headers => {
    'Authorization': 'Bearer ${config.apiKey}',
  };

  @override
  Future<BalanceInfo> getBalance() async {
    // Call provider's balance API
  }

  @override
  Future<UsageInfo> getUsage() async {
    // Call provider's usage API
  }
}
```

## Getting Started

### Prerequisites

- Flutter 3.38+
- Xcode 16+ (for iOS builds)
- iOS 16.0+ deployment target

### Development

```bash
# Clone the repo
git clone https://github.com/jphermans/ai-balance-tracker.git
cd ai-balance-tracker

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run on connected iPhone
flutter run -d <device_id>
```

### Build IPA for Sideloading

**Option 1: Download unsigned IPA from CI (simplest)**

1. Go to [Actions → Build iOS IPA](https://github.com/jphermans/ai-balance-tracker/actions/workflows/build-ipa.yml)
2. Click the latest successful run
3. Download `ai-balance-tracker-unsigned-ipa` artifact
4. Unzip and re-sign with your own certificate:

```bash
# Unzip the IPA
unzip ai-balance-tracker-unsigned.ipa -d extracted

# Sign with your own cert (macOS)
codesign -fs "iPhone Developer: Your Name (TEAMID)" \
  --entitlements entitlements.plist \
  extracted/Payload/Runner.app

# Re-package
cd extracted && zip -r ../ai-balance-tracker-signed.ipa Payload/

# Install via Xcode, Apple Configurator, or sideloading tool
```

**Option 2: Build locally**

```bash
# Build unsigned
flutter build ios --no-codesign

# Package into IPA
mkdir Payload
cp -R build/ios/Release-iphoneos/Runner.app Payload/
zip -r ai-balance-tracker.ipa Payload/

# Sign and install with ios-deploy
ios-deploy --bundle Payload/Runner.app
```

**Option 3: Signed build (requires Apple Developer account)**

Set up the GitHub Secrets listed in `.github/workflows/build-ipa.yml`, then the CI produces a fully signed ad-hoc IPA ready to sideload via Xcode or Apple Configurator.

## Security

- API keys are stored in the **iOS Keychain** via `flutter_secure_storage`
- No credentials in SharedPreferences, logs, or crash reports
- Sensitive values are masked in the UI
- HTTPS-only API communication
- Keys are never transmitted to third-party servers

## CI/CD

This repo includes a GitHub Actions workflow (`.github/workflows/build-ipa.yml`) that:

1. Builds the Flutter iOS app on a macOS runner
2. Produces an ad-hoc IPA file for sideloading
3. Uploads the IPA as a workflow artifact

### Setup

Add these secrets to your GitHub repo:

| Secret | Description |
|--------|-------------|
| `APPLE_DEVELOPER_CERTIFICATE_BASE64` | P12 certificate (base64-encoded) |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | P12 certificate password |
| `APPLE_PROVISION_PROFILE_BASE64` | Ad-hoc provisioning profile (base64-encoded) |
| `APPLE_TEAM_ID` | Your Apple Developer team ID |
| `APPLE_EXPORT_PASSWORD` | Password for IPA export |

## License

MIT © JPHsystems
