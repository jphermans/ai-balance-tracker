class ProviderConfig {
  final String id;
  final ProviderType type;
  final String apiKey;
  final String? orgId;
  final String? accountId;
  final String? customEndpoint;
  final bool enabled;
  final DateTime? updatedAt; // Cloud sync timestamp; null = local-only

  const ProviderConfig({
    required this.id,
    required this.type,
    required this.apiKey,
    this.orgId,
    this.accountId,
    this.customEndpoint,
    this.enabled = true,
    this.updatedAt,
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      id: json['id'] as String,
      type: ProviderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProviderType.openai,
      ),
      apiKey: json['apiKey'] as String,
      orgId: json['orgId'] as String?,
      accountId: json['accountId'] as String?,
      customEndpoint: json['customEndpoint'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'apiKey': apiKey,
        if (orgId != null) 'orgId': orgId,
        if (accountId != null) 'accountId': accountId,
        if (customEndpoint != null) 'customEndpoint': customEndpoint,
        'enabled': enabled,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  ProviderConfig copyWith({
    String? apiKey,
    String? orgId,
    String? accountId,
    String? customEndpoint,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return ProviderConfig(
      id: id,
      type: type,
      apiKey: apiKey ?? this.apiKey,
      orgId: orgId ?? this.orgId,
      accountId: accountId ?? this.accountId,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ProviderType {
  openai,
  anthropic,
  deepseek,
  googleAI,
  openrouter,
  xai,
  cohere,
  mistral,
  together,
  fireworks,
  groq,
  perplexity,
  novita,
  siliconflow,
  moonshot,
  cerebras,
  replicate,
  huggingface,
  sambanova,
  ai21,
  qwen;

  String get displayName {
    switch (this) {
      case ProviderType.openai:
        return 'OpenAI';
      case ProviderType.anthropic:
        return 'Anthropic';
      case ProviderType.deepseek:
        return 'DeepSeek';
      case ProviderType.googleAI:
        return 'Google AI Studio';
      case ProviderType.openrouter:
        return 'OpenRouter';
      case ProviderType.xai:
        return 'xAI';
      case ProviderType.cohere:
        return 'Cohere';
      case ProviderType.mistral:
        return 'Mistral AI';
      case ProviderType.together:
        return 'Together AI';
      case ProviderType.fireworks:
        return 'Fireworks AI';
      case ProviderType.groq:
        return 'Groq';
      case ProviderType.perplexity:
        return 'Perplexity';
      case ProviderType.novita:
        return 'Novita AI';
      case ProviderType.siliconflow:
        return 'SiliconFlow';
      case ProviderType.moonshot:
        return 'Kimi';
      case ProviderType.cerebras:
        return 'Cerebras';
      case ProviderType.replicate:
        return 'Replicate';
      case ProviderType.huggingface:
        return 'Hugging Face';
      case ProviderType.sambanova:
        return 'SambaNova';
      case ProviderType.ai21:
        return 'AI21 Labs';
      case ProviderType.qwen:
        return 'Qwen (Alibaba)';
    }
  }

  String get baseUrl {
    switch (this) {
      case ProviderType.openai:
        return 'https://api.openai.com';
      case ProviderType.anthropic:
        return 'https://api.anthropic.com';
      case ProviderType.deepseek:
        return 'https://api.deepseek.com';
      case ProviderType.googleAI:
        return 'https://generativelanguage.googleapis.com';
      case ProviderType.openrouter:
        return 'https://openrouter.ai/api';
      case ProviderType.xai:
        return 'https://api.x.ai';
      case ProviderType.cohere:
        return 'https://api.cohere.ai';
      case ProviderType.mistral:
        return 'https://api.mistral.ai';
      case ProviderType.together:
        return 'https://api.together.xyz';
      case ProviderType.fireworks:
        return 'https://api.fireworks.ai';
      case ProviderType.groq:
        return 'https://api.groq.com';
      case ProviderType.perplexity:
        return 'https://api.perplexity.ai';
      case ProviderType.novita:
        return 'https://api.novita.ai';
      case ProviderType.siliconflow:
        return 'https://api.siliconflow.cn';
      case ProviderType.moonshot:
        return 'https://api.moonshot.ai';
      case ProviderType.cerebras:
        return 'https://api.cerebras.ai';
      case ProviderType.replicate:
        return 'https://api.replicate.com';
      case ProviderType.huggingface:
        return 'https://huggingface.co';
      case ProviderType.sambanova:
        return 'https://api.sambanova.ai';
      case ProviderType.ai21:
        return 'https://api.ai21.com';
      case ProviderType.qwen:
        return 'https://dashscope-intl.aliyuncs.com/compatible-mode';
    }
  }

  bool get hasBalanceEndpoint {
    switch (this) {
      case ProviderType.openai:
      case ProviderType.anthropic:
      case ProviderType.deepseek:
      case ProviderType.openrouter:
      case ProviderType.groq:
      case ProviderType.together:
      case ProviderType.siliconflow:
      case ProviderType.moonshot:
      case ProviderType.qwen:
        return true;
      default:
        return false;
    }
  }
}
