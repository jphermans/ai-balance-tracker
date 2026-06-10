import '../models/provider_config.dart';
import 'ai_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';
import 'deepseek_provider.dart';
import 'openrouter_provider.dart';
import 'groq_provider.dart';
import 'together_provider.dart';
import 'siliconflow_provider.dart';
import 'moonshot_provider.dart';
import 'qwen_provider.dart';
import 'minimax_provider.dart';
import 'stub_provider.dart';

/// Registry that maps ProviderType to the correct AIProvider implementation.
class ProviderRegistry {
  const ProviderRegistry._();

  /// Create the appropriate AIProvider adapter for the given config.
  static AIProvider create(ProviderConfig config) {
    switch (config.type) {
      case ProviderType.openai:
        return OpenAIProvider(config);
      case ProviderType.anthropic:
        return AnthropicProvider(config);
      case ProviderType.deepseek:
        return DeepSeekProvider(config);
      case ProviderType.openrouter:
        return OpenRouterProvider(config);
      case ProviderType.groq:
        return GroqProvider(config);
      case ProviderType.together:
        return TogetherProvider(config);
      case ProviderType.siliconflow:
        return SiliconFlowProvider(config);
      case ProviderType.moonshot:
        return MoonshotProvider(config);
      case ProviderType.qwen:
        return QwenProvider(config);
      case ProviderType.minimax:
        return MinimaxProvider(config);
      // All other providers use the stub
      default:
        return StubProvider(config);
    }
  }

  /// List of provider types that support full balance checking.
  static const balanceProviders = {
    ProviderType.openai,
    ProviderType.anthropic,
    ProviderType.deepseek,
    ProviderType.openrouter,
    ProviderType.together,
    ProviderType.siliconflow,
    ProviderType.moonshot,
  };
}
