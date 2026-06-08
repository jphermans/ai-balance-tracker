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
}
