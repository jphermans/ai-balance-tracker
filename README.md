# AI Balance Tracker

> Securely monitor credits, usage, and funds across all your AI providers in a unified dashboard.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-17.0+-000000?logo=apple)](https://apple.com/ios)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.12.0-blue)](https://github.com/jphermans/ai-balance-tracker/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?logo=apple)](https://apple.com/macos)

## Features

- **Unified Dashboard** — View balances from all your AI providers in one place
- **Auto-Refresh on Launch** — Balances load automatically when the app starts
- **Offline Banner** — Orange banner warns when device has no network connection
- **9 providers with full balance tracking** — OpenAI, Anthropic, DeepSeek, OpenRouter, Together AI, Groq, SiliconFlow, Kimi
- **20 providers total** — 11 use key validation, 1 added: Qwen (Alibaba Cloud)
- **Spending History Chart** — 7/30/90-day balance snapshots with interactive line chart and touch tooltips
- **CSV Export** — Export provider data and spending history via share sheet
- **Color-Coded Provider Cards** — Green/orange/red balance threshold indicators (≥10/≥5/<5)
- **App Banner** — Full-width JPHsystems banner image on about screen
- **Optional PIN Lock** — Full-screen PIN setup on first launch + polished unlock screen (stored in iOS Keychain)
- **Secure Storage** — API keys and PIN stored in iOS Keychain, never in plain text
- **About Screen** — App info, tech stack, features list, GitHub links
- **Dark & Light Mode** — Material 3 with automatic/system theme switching
- **Provider Adapters** — Clean architecture: add new providers by implementing `AIProvider`
- **Custom App Icon** — AI-themed neural network icon with gradient purple/blue palette
- **Unsigned IPA in CI** — Every push produces a downloadable IPA for sideloading
- **Developer Mode** — View raw API responses + endpoint URL per provider (always visible on detail screen)
- **Model Browser** — Browse 50+ models with pricing, context window, and capabilities across all providers
- **Balance Not Supported Banner** — Cards clearly indicate when a provider only supports key validation
- **iOS Liquid Glass Design** — Frosted translucent surfaces, BackdropFilter blur, dark/light adaptive glass throughout the app
- **macOS Desktop App** — Native macOS build with fixed 800×600 window, separate Intel and Apple Silicon downloads

## Supported Providers

| Provider | Balance API | Key Validation |
|----------|:-----------:|:--------------:|
| OpenAI | ✅ | ✅ |
| Anthropic | ✅ | ✅ |
| DeepSeek | ✅ | ✅ |
| OpenRouter | ✅ | ✅ |
| Together AI | ✅ | ✅ |
| SiliconFlow | ✅ | ✅ |
| Kimi | ✅ | ✅ |
| Qwen (Alibaba) | ❌ | ✅ |
| Groq | ⚠️ | ✅ |
| Google AI Studio | ❌ | ✅ |
| xAI | ❌ | ✅ |
| Cohere | ❌ | ✅ |
| Mistral AI | ❌ | ✅ |
| Fireworks AI | ❌ | ✅ |
| Perplexity | ❌ | ✅ |
| Novita AI | ❌ | ✅ |
| Cerebras | ❌ | ✅ |
| Replicate | ❌ | ✅ |
| Hugging Face | ❌ | ✅ |
| SambaNova | ❌ | ✅ |
| AI21 Labs | ❌ | ✅ |

✅ Full balance tracking &nbsp;&nbsp; ⚠️ Key validation only (shown on card) &nbsp;&nbsp; ❌ Key validation only

## Architecture

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + PIN unlock check + routing
├── screens/
│   ├── dashboard_screen.dart    # Provider cards, search, pull-to-refresh
│   ├── provider_detail_screen.dart  # Stats, usage chart, raw API, model browser
│   ├── settings_screen.dart     # Theme, PIN lock, provider management
│   ├── add_provider_screen.dart # Searchable provider list + API key entry
│   ├── pin_unlock_screen.dart   # Full-screen PIN entry with shake animation
│   ├── pin_setup_screen.dart    # Full-screen PIN creation + confirmation
│   └── about_screen.dart        # App info, tech stack, links, license
├── models/
│   ├── balance_info.dart        # Balance data model (supportsBalance flag)
│   ├── balance_snapshot.dart     # Timestamped balance for spending history
│   ├── usage_info.dart          # Usage statistics model
│   ├── model_info.dart          # Model metadata (pricing, context, capabilities)
│   └── provider_config.dart     # Provider configuration + 19 provider types
├── providers/
│   ├── ai_provider.dart         # Abstract base class
│   ├── openai_provider.dart     # /v1/dashboard/billing/credit_grants
│   ├── anthropic_provider.dart  # /v1/organizations/{id}/usage
│   ├── deepseek_provider.dart   # /user/balance
│   ├── openrouter_provider.dart # /api/v1/credits
│   ├── groq_provider.dart       # Key validation via /models
│   ├── together_provider.dart   # /v1/billing
│   ├── siliconflow_provider.dart # /v1/user/info
│   ├── moonshot_provider.dart   # Kimi api.moonshot.ai/v1/users/me/balance
│   ├── qwen_provider.dart       # Qwen dashscope /compatible-mode/v1/models
│   ├── stub_provider.dart       # Key validation for 10 other providers
│   └── provider_registry.dart   # Provider → adapter mapping
├── services/
│   ├── secure_storage_service.dart  # Keychain-backed credential storage
│   ├── balance_service.dart         # Parallel balance fetching
│   ├── history_service.dart         # Balance snapshots + spending chart data
│   ├── widget_data_service.dart     # Writes balance to App Group UserDefaults
│   └── pin_service.dart             # PIN hash/verify/remove (Keychain)
├── state/
│   └── app_state.dart           # Riverpod: providers, balances, theme, PIN
├── theme/
│   └── app_theme.dart           # Material 3 light/dark iOS-inspired themes
└── widgets/
    ├── splash_screen.dart       # Branded launch screen with animations
    ├── provider_card.dart       # Balance card with not-supported banner
    ├── glass_card.dart          # Liquid glass card with BackdropFilter blur
    ├── pin_pad.dart             # Shared numeric PIN keypad (iOS style)
    └── pin_setup_dialog.dart    # Create/confirm PIN (legacy bottom sheet)
```

### iOS Widget Extension (native)

```
ios/BalanceWidget/
├── Info.plist                          # Widget extension metadata
├── BalanceWidgetBundle.swift           # @main WidgetBundle entry point
├── BalanceWidget.swift                 # WidgetConfiguration + SwiftUI view
├── BalanceProvider.swift               # TimelineProvider reading App Group
└── BalanceWidget.entitlements          # App Group capability
```

**Data flow:** Flutter → MethodChannel → App Group UserDefaults → Widget reads on timeline refresh

> ⚠️ **Widget requires a paid Apple Developer account.** Free provisioning profiles don't support app extensions. The IPA built by CI does NOT include the widget. To enable it locally: add the `BalanceWidgetExtension` target to the Xcode scheme via `ios/add_widget_target.py`.

### macOS (native desktop)

```
macos/
├── Runner/
│   ├── MainFlutterWindow.swift    # Fixed 800×600 non-resizable window
│   ├── AppDelegate.swift          # macOS app delegate
│   ├── Info.plist                 # App metadata
│   └── Configs/                   # Build configs (Debug, Release)
└── Runner.xcodeproj/              # Xcode project
```

**Window:** 800×600 fixed size, centered on screen, no resize, vertical scroll only.

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/` | Provider cards, search, pull-to-refresh balances |
| Provider Detail | `/provider/:id` | Stats, usage chart, raw API, model browser |
| Add Provider | `/add-provider` | Searchable provider list + API key entry |
| Settings | `/settings` | Theme, PIN lock, provider list, data management |
| PIN Setup | `/pin-setup` | Full-screen 4-digit PIN creation with confirmation |
| PIN Unlock | (gate) | Full-screen unlock with shake on wrong PIN |
| About | `/about` | App info, tech stack, features, links, license |

### Adding a New Provider

1. Create a class in `lib/providers/` extending `AIProvider`
2. Implement `getBalance()` and `getUsage()`
3. Add the type to `ProviderType` enum in `provider_config.dart`
4. Register it in `ProviderRegistry.create()`
5. Set `hasBalanceEndpoint` to `true` if the provider has a balance API

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
- iOS 17.0+ deployment target
- macOS 13.0+ (for desktop builds)

### Development

```bash
git clone https://github.com/jphermans/ai-balance-tracker.git
cd ai-balance-tracker
flutter pub get
flutter run          # iOS simulator
flutter run -d macos # macOS desktop
flutter run -d <id>  # connected iPhone
```

## macOS Desktop Build

The CI builds separate Intel (x86_64) and Apple Silicon (arm64) .app bundles.

### Download

Go to [Actions → Build macOS App](https://github.com/jphermans/ai-balance-tracker/actions/workflows/build-macos.yml) → click the latest run → download the artifact for your chipset.

Or grab the latest from [Releases](https://github.com/jphermans/ai-balance-tracker/releases) (tagged builds only):

- `ai-balance-tracker-macos-arm64.zip` — Apple Silicon (M1/M2/M3/M4)
- `ai-balance-tracker-macos-intel.zip` — Intel Macs

### Install

```bash
# Unzip and drag to /Applications
unzip ai-balance-tracker-macos-arm64.zip
mv "AI Balance Tracker.app" /Applications/

# If macOS blocks it (unidentified developer):
xattr -cr "/Applications/AI Balance Tracker.app"
```

### Local build

```bash
flutter build macos --release
open build/macos/Build/Products/Release/
```

## Building & Sideloading the IPA

The CI builds an unsigned IPA on every push. You download it, sign it with your own certificate, and install it on your device.

### Step 1: Download the IPA

Go to [Actions → Build iOS IPA](https://github.com/jphermans/ai-balance-tracker/actions/workflows/build-ipa.yml) → click the latest run → scroll to **Artifacts** → download `ai-balance-tracker-unsigned-ipa`.

### Step 2: Get a Signing Certificate

**If you have an Apple Developer account ($99/year):**
```bash
# Your cert is already in Keychain. List it:
security find-identity -v -p codesigning
# Look for "iPhone Developer: Your Name (TEAMID)"
```

**If you don't have a paid account (free sideloading, 7-day expiry):**
1. Open Xcode → Preferences → Accounts → add your Apple ID
2. Create a new dummy iOS project (any template)
3. Set the bundle ID to `com.jphermans.ai-balance-tracker`
4. Build to your device once — Xcode creates a free provisioning profile
5. Your signing identity is now: `Apple Development: your@email.com (TEAMID)`

Find your identity:
```bash
security find-identity -v -p codesigning
```

### Step 3: Create Entitlements

Create a file `entitlements.plist` (or use the one in `ios/entitlements.plist` from the repo):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>YOUR_TEAM_ID.com.jphermans.ai-balance-tracker</string>
    <key>com.apple.developer.team-identifier</key>
    <string>YOUR_TEAM_ID</string>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your actual team ID (find it at [developer.apple.com/account](https://developer.apple.com/account)).

### Step 4: Sign the IPA

```bash
# Unzip the IPA
unzip ai-balance-tracker-unsigned.ipa -d extracted

# Sign the app with your certificate
codesign -fs "iPhone Developer: Your Name (TEAMID)" \
  --entitlements entitlements.plist \
  extracted/Payload/Runner.app

# Verify the signature
codesign -dvvv extracted/Payload/Runner.app

# Re-package into a signed IPA
cd extracted
zip -r ../ai-balance-tracker-signed.ipa Payload/
cd ..
```

### Step 5: Install on Your iPhone

**Option A — Xcode (easiest):**
1. Connect iPhone via USB
2. Xcode → Window → Devices and Simulators
3. Drag the signed `.ipa` onto your device

**Option B — Apple Configurator (Mac App Store, free):**
1. Connect iPhone via USB
2. Drag the signed `.ipa` onto your device in Apple Configurator

**Option C — ios-deploy (command line):**
```bash
brew install ios-deploy
ios-deploy --bundle extracted/Payload/Runner.app
```

**Option D — AltStore / SideStore:**
Use a sideloading tool that handles re-signing automatically.

### Automated Signed Build (optional)

Add these GitHub Secrets for CI to produce a fully signed IPA:

| Secret | How to get it |
|--------|---------------|
| `APPLE_DEVELOPER_CERTIFICATE_BASE64` | `base64 -i ~/Desktop/certificate.p12` |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | P12 export password |
| `APPLE_PROVISION_PROFILE_BASE64` | `base64 -i ~/Downloads/app.mobileprovision` |
| `APPLE_TEAM_ID` | From [developer.apple.com/account](https://developer.apple.com/account) |

## PIN Lock

The app includes an optional 4-digit PIN lock with a polished setup flow:

- **First launch:** After splash, if no PIN exists → full-screen onboarding PIN setup with skip option
- **Set PIN later:** Settings → Security → Set PIN → full-screen setup page → enter + confirm
- **Remove PIN:** Settings → Security → Remove → enter current PIN in dialog
- **Unlock on return:** Full-screen PIN entry with animated dots and shake on wrong attempts
- **Storage:** PIN hash stored in iOS Keychain via `flutter_secure_storage`

## Security

- API keys and PIN stored in **iOS Keychain** via `flutter_secure_storage`
- PIN is hashed before storage (not plaintext)
- No credentials in SharedPreferences, logs, or crash reports
- Sensitive values masked in UI
- HTTPS-only API communication

## CI/CD

The `.github/workflows/build-ipa.yml` workflow:

| Job | Trigger | Output |
|-----|---------|--------|
| **Unsigned IPA** | Every push to `main` | `ai-balance-tracker-unsigned.ipa` artifact |
| **Signed IPA** | Push to `main` (requires Apple secrets) | Signed ad-hoc IPA artifact |
| **GitHub Release** | Tag push (`v*`) | Both IPAs + macOS builds attached to release |

The `.github/workflows/build-macos.yml` workflow:

| Job | Trigger | Output |
|-----|---------|--------|
| **macOS Intel** | Every push to `main` | `ai-balance-tracker-macos-intel.zip` |
| **macOS ARM64** | Every push to `main` | `ai-balance-tracker-macos-arm64.zip` |
| **GitHub Release** | Tag push (`v*`) | Both macOS zips attached |

## License

MIT © JPHsystems
