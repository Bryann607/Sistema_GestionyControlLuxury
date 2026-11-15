class PaymentEntry {
  const PaymentEntry({
    required this.method,
    required this.amount,
    required this.createdAt,
    this.reference = '',
    this.cashReceived,
  });

  final String method;
  final double amount;
  final DateTime createdAt;
  final String reference;
  final double? cashReceived;

  double get change => cashReceived == null
      ? 0
      : (cashReceived! - amount).clamp(0, double.infinity).toDouble();

  Map<String, dynamic> toJson() => {
    'method': method,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'reference': reference,
    'cashReceived': cashReceived,
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    method: json['method'] as String,
    amount: (json['amount'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    reference: json['reference'] as String? ?? '',
    cashReceived: (json['cashReceived'] as num?)?.toDouble(),
  );
}
