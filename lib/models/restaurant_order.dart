import 'package:luxury_app/models/order_line.dart';
import 'package:luxury_app/models/order_status.dart';
import 'package:luxury_app/models/payment_entry.dart';

class RestaurantOrder {
  const RestaurantOrder({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.createdAt,
    required this.lines,
    this.diners = 1,
    this.status = OrderStatus.pending,
    this.payments = const [],
    this.waiterName = 'Equipo Luxury',
    this.incident = '',
    this.parentOrderId,
    this.retirementConfirmed = false,
  });

  final int id;
  final int tableId;
  final int tableNumber;
  final DateTime createdAt;
  final int diners;
  final List<OrderLine> lines;
  final OrderStatus status;
  final List<PaymentEntry> payments;
  final String waiterName;
  final String incident;
  final int? parentOrderId;
  final bool retirementConfirmed;

  double get total => lines.fold(0, (sum, line) => sum + line.subtotal);
  double get paid => payments.fold(0, (sum, payment) => sum + payment.amount);
  double get balance => (total - paid).clamp(0, total).toDouble();

  RestaurantOrder copyWith({
    int? id,
    List<OrderLine>? lines,
    OrderStatus? status,
    List<PaymentEntry>? payments,
    String? waiterName,
    String? incident,
    int? diners,
    int? parentOrderId,
    bool? retirementConfirmed,
  }) => RestaurantOrder(
    id: id ?? this.id,
    tableId: tableId,
    tableNumber: tableNumber,
    createdAt: createdAt,
    diners: diners ?? this.diners,
    lines: lines ?? this.lines,
    status: status ?? this.status,
    payments: payments ?? this.payments,
    waiterName: waiterName ?? this.waiterName,
    incident: incident ?? this.incident,
    parentOrderId: parentOrderId ?? this.parentOrderId,
    retirementConfirmed: retirementConfirmed ?? this.retirementConfirmed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableId': tableId,
    'tableNumber': tableNumber,
    'createdAt': createdAt.toIso8601String(),
    'diners': diners,
    'lines': lines.map((line) => line.toJson()).toList(),
    'status': status.databaseValue,
    'payments': payments.map((payment) => payment.toJson()).toList(),
    'waiterName': waiterName,
    'incident': incident,
    'parentOrderId': parentOrderId,
    'retirementConfirmed': retirementConfirmed,
  };

  factory RestaurantOrder.fromJson(
    Map<String, dynamic> json,
  ) => RestaurantOrder(
    id: json['id'] as int,
    tableId: json['tableId'] as int,
    tableNumber: json['tableNumber'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    diners: json['diners'] as int? ?? 1,
    lines: (json['lines'] as List<dynamic>)
        .map(
          (line) => OrderLine.fromJson(Map<String, dynamic>.from(line as Map)),
        )
        .toList(),
    status: OrderStatus.fromDatabase(json['status'] as String),
    payments: (json['payments'] as List<dynamic>? ?? [])
        .map(
          (payment) =>
              PaymentEntry.fromJson(Map<String, dynamic>.from(payment as Map)),
        )
        .toList(),
    waiterName: json['waiterName'] as String? ?? 'Equipo Luxury',
    incident: json['incident'] as String? ?? '',
    parentOrderId: json['parentOrderId'] as int?,
    retirementConfirmed: json['retirementConfirmed'] as bool? ?? false,
  );
}

OrderStatus kitchenStage(RestaurantOrder order) {
  if (order.lines.any((line) => line.status == OrderStatus.pending)) {
    return OrderStatus.pending;
  }
  if (order.lines.any((line) => line.status == OrderStatus.preparing)) {
    return OrderStatus.preparing;
  }
  if (order.lines.any((line) => line.status == OrderStatus.ready)) {
    return OrderStatus.ready;
  }
  return OrderStatus.delivered;
}
