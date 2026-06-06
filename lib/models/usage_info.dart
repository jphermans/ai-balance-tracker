class UsageInfo {
  final double spentThisMonth;
  final double totalCredits;
  final double? requestsThisMonth;
  final double? tokensThisMonth;
  final String? currency;

  const UsageInfo({
    required this.spentThisMonth,
    required this.totalCredits,
    this.requestsThisMonth,
    this.tokensThisMonth,
    this.currency,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      spentThisMonth: (json['spentThisMonth'] as num).toDouble(),
      totalCredits: (json['totalCredits'] as num).toDouble(),
      requestsThisMonth: json['requestsThisMonth'] != null
          ? (json['requestsThisMonth'] as num).toDouble()
          : null,
      tokensThisMonth: json['tokensThisMonth'] != null
          ? (json['tokensThisMonth'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'spentThisMonth': spentThisMonth,
        'totalCredits': totalCredits,
        if (requestsThisMonth != null) 'requestsThisMonth': requestsThisMonth,
        if (tokensThisMonth != null) 'tokensThisMonth': tokensThisMonth,
        if (currency != null) 'currency': currency,
      };
}
