class BalanceInfo {
  final String providerId;
  final String providerName;
  final double balance;
  final String currency;
  final double? totalSpent;
  final double? totalCredits;
  final DateTime lastUpdated;
  final BalanceStatus status;
  final Map<String, dynamic>? rawResponse;

  const BalanceInfo({
    required this.providerId,
    required this.providerName,
    required this.balance,
    required this.currency,
    this.totalSpent,
    this.totalCredits,
    required this.lastUpdated,
    required this.status,
    this.rawResponse,
  });

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      totalSpent: json['totalSpent'] != null
          ? (json['totalSpent'] as num).toDouble()
          : null,
      totalCredits: json['totalCredits'] != null
          ? (json['totalCredits'] as num).toDouble()
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      status: BalanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BalanceStatus.unknown,
      ),
      rawResponse: json['rawResponse'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'providerName': providerName,
        'balance': balance,
        'currency': currency,
        'totalSpent': totalSpent,
        'totalCredits': totalCredits,
        'lastUpdated': lastUpdated.toIso8601String(),
        'status': status.name,
        'rawResponse': rawResponse,
      };

  BalanceInfo copyWith({
    String? providerId,
    String? providerName,
    double? balance,
    String? currency,
    double? totalSpent,
    double? totalCredits,
    DateTime? lastUpdated,
    BalanceStatus? status,
    Map<String, dynamic>? rawResponse,
  }) {
    return BalanceInfo(
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      totalSpent: totalSpent ?? this.totalSpent,
      totalCredits: totalCredits ?? this.totalCredits,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

enum BalanceStatus {
  active,
  invalidKey,
  unavailable,
  unknown;

  String get displayName {
    switch (this) {
      case BalanceStatus.active:
        return 'Active';
      case BalanceStatus.invalidKey:
        return 'Invalid API Key';
      case BalanceStatus.unavailable:
        return 'API Unavailable';
      case BalanceStatus.unknown:
        return 'Unknown';
    }
  }
}
