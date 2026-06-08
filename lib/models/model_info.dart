/// Represents an AI model available from a provider, with optional pricing.
class ModelInfo {
  final String id;
  final String displayName;
  final double? inputPricePer1M; // USD per 1M input tokens
  final double? outputPricePer1M; // USD per 1M output tokens
  final int? contextWindow;
  final String? capabilities; // e.g. "text", "image"

  const ModelInfo({
    required this.id,
    required this.displayName,
    this.inputPricePer1M,
    this.outputPricePer1M,
    this.contextWindow,
    this.capabilities,
  });

  /// Create a ModelInfo and enrich with known pricing if not provided.
  factory ModelInfo.enriched({
    required String id,
    required String displayName,
    double? inputPricePer1M,
    double? outputPricePer1M,
    int? contextWindow,
    String? capabilities,
  }) {
    final known = _pricingDb[id] ?? _pricingDb[displayName];
    return ModelInfo(
      id: id,
      displayName: displayName,
      inputPricePer1M: inputPricePer1M ?? known?.input,
      outputPricePer1M: outputPricePer1M ?? known?.output,
      contextWindow: contextWindow ?? known?.ctx,
      capabilities: capabilities,
    );
  }

  /// Format price for display, or empty string if not available.
  String get priceDisplay {
    if (inputPricePer1M == null && outputPricePer1M == null) return '';
    final inPrice = inputPricePer1M != null
        ? '\$${inputPricePer1M!.toStringAsFixed(2)}'
        : '—';
    final outPrice = outputPricePer1M != null
        ? '\$${outputPricePer1M!.toStringAsFixed(2)}'
        : '—';
    return '$inPrice / $outPrice per 1M tokens';
  }

  String get contextDisplay {
    if (contextWindow == null) return '';
    if (contextWindow! >= 1000) {
      return '${(contextWindow! / 1000).toStringAsFixed(0)}K ctx';
    }
    return '${contextWindow} ctx';
  }

  /// Known pricing & context window for popular models (USD per 1M tokens).
  /// Prices approximate as of mid-2025. Updated periodically.
  static const Map<String, _ModelPricing> _pricingDb = {
    // OpenAI
    'gpt-4o': _ModelPricing(input: 2.50, output: 10.00, ctx: 128000),
    'gpt-4o-mini': _ModelPricing(input: 0.15, output: 0.60, ctx: 128000),
    'gpt-4-turbo': _ModelPricing(input: 10.00, output: 30.00, ctx: 128000),
    'gpt-4': _ModelPricing(input: 30.00, output: 60.00, ctx: 8192),
    'gpt-3.5-turbo': _ModelPricing(input: 0.50, output: 1.50, ctx: 16385),
    'o1': _ModelPricing(input: 15.00, output: 60.00, ctx: 200000),
    'o1-mini': _ModelPricing(input: 1.10, output: 4.40, ctx: 128000),
    'o3-mini': _ModelPricing(input: 1.10, output: 4.40, ctx: 200000),
    // Anthropic
    'claude-3-5-sonnet-20241022': _ModelPricing(input: 3.00, output: 15.00, ctx: 200000),
    'claude-3-5-haiku-20241022': _ModelPricing(input: 0.80, output: 4.00, ctx: 200000),
    'claude-3-opus-20240229': _ModelPricing(input: 15.00, output: 75.00, ctx: 200000),
    'claude-3-sonnet-20240229': _ModelPricing(input: 3.00, output: 15.00, ctx: 200000),
    'claude-3-haiku-20240307': _ModelPricing(input: 0.25, output: 1.25, ctx: 200000),
    'claude-sonnet-4-20250514': _ModelPricing(input: 3.00, output: 15.00, ctx: 200000),
    'claude-opus-4-20250514': _ModelPricing(input: 15.00, output: 75.00, ctx: 200000),
    // DeepSeek
    'deepseek-chat': _ModelPricing(input: 0.27, output: 1.10, ctx: 128000),
    'deepseek-reasoner': _ModelPricing(input: 0.55, output: 2.19, ctx: 128000),
    // Google
    'gemini-1.5-pro': _ModelPricing(input: 1.25, output: 5.00, ctx: 2097152),
    'gemini-1.5-flash': _ModelPricing(input: 0.075, output: 0.30, ctx: 1048576),
    'gemini-2.0-flash': _ModelPricing(input: 0.10, output: 0.40, ctx: 1048576),
    'gemini-2.5-pro': _ModelPricing(input: 1.25, output: 10.00, ctx: 1048576),
    // Mistral
    'mistral-large-latest': _ModelPricing(input: 2.00, output: 6.00, ctx: 128000),
    'mistral-small-latest': _ModelPricing(input: 0.20, output: 0.60, ctx: 32000),
    'mistral-medium': _ModelPricing(input: 2.70, output: 8.10, ctx: 32000),
    'codestral': _ModelPricing(input: 0.30, output: 0.90, ctx: 256000),
    // Groq
    'llama-3.3-70b-versatile': _ModelPricing(input: 0.59, output: 0.79, ctx: 128000),
    'llama-3.1-8b-instant': _ModelPricing(input: 0.05, output: 0.08, ctx: 128000),
    'mixtral-8x7b-32768': _ModelPricing(input: 0.24, output: 0.24, ctx: 32768),
    'gemma2-9b-it': _ModelPricing(input: 0.20, output: 0.20, ctx: 8192),
    // xAI
    'grok-2': _ModelPricing(input: 2.00, output: 10.00, ctx: 128000),
    'grok-2-mini': _ModelPricing(input: 0.55, output: 2.20, ctx: 128000),
    // Together AI
    'meta-llama/Llama-3.3-70B-Instruct-Turbo': _ModelPricing(input: 0.88, output: 0.88, ctx: 128000),
    'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo': _ModelPricing(input: 0.18, output: 0.18, ctx: 128000),
    // Cohere
    'command-r-plus': _ModelPricing(input: 2.50, output: 10.00, ctx: 128000),
    'command-r': _ModelPricing(input: 0.50, output: 1.50, ctx: 128000),
    // Qwen (Alibaba Cloud)
    'qwen-turbo': _ModelPricing(input: 0.30, output: 0.60, ctx: 131072),
    'qwen-plus': _ModelPricing(input: 0.80, output: 2.00, ctx: 131072),
    'qwen-max': _ModelPricing(input: 2.40, output: 9.60, ctx: 32768),
    'qwen-long': _ModelPricing(input: 0.50, output: 2.00, ctx: 10485760),
    'qwen-vl-plus': _ModelPricing(input: 1.50, output: 4.50, ctx: 32768),
    'qwen-vl-max': _ModelPricing(input: 3.00, output: 9.00, ctx: 32768),
    'qwen2.5-72b-instruct': _ModelPricing(input: 0.55, output: 2.20, ctx: 131072),
    'qwen2.5-32b-instruct': _ModelPricing(input: 0.35, output: 1.40, ctx: 131072),
    'qwen2.5-14b-instruct': _ModelPricing(input: 0.20, output: 0.80, ctx: 131072),
    'qwen2.5-7b-instruct': _ModelPricing(input: 0.10, output: 0.40, ctx: 131072),
    'qwen-coder-plus': _ModelPricing(input: 0.80, output: 2.00, ctx: 131072),
    'qwen-coder-turbo': _ModelPricing(input: 0.30, output: 0.60, ctx: 131072),
  };
}

class _ModelPricing {
  final double input;
  final double output;
  final int ctx;
  const _ModelPricing({required this.input, required this.output, required this.ctx});
}
