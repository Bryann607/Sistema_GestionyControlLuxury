import 'package:luxury_app/models/order_status.dart';

class OrderLine {
  const OrderLine({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.note = '',
    this.status = OrderStatus.pending,
    this.id,
  });

  final int? id;
  final int menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String note;
  final OrderStatus status;
  double get subtotal => quantity * unitPrice;

  OrderLine copyWith({
    int? id,
    int? quantity,
    String? note,
    OrderStatus? status,
  }) => OrderLine(
    id: id ?? this.id,
    menuItemId: menuItemId,
    name: name,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice,
    note: note ?? this.note,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'menuItemId': menuItemId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'note': note,
    'status': status.databaseValue,
  };

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    id: json['id'] as int?,
    menuItemId: json['menuItemId'] as int,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    note: json['note'] as String? ?? '',
    status: OrderStatus.fromDatabase(json['status'] as String? ?? 'PENDIENTE'),
  );
}
