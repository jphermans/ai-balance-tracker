class BalanceSnapshot {
  final String providerId;
  final double balance;
  final DateTime date;

  const BalanceSnapshot({
    required this.providerId,
    required this.balance,
    required this.date,
  });

  factory BalanceSnapshot.fromJson(Map<String, dynamic> json) {
    return BalanceSnapshot(
      providerId: json['providerId'] as String,
      balance: (json['balance'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'balance': balance,
        'date': date.toIso8601String(),
      };
}
