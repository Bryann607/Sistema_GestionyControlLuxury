import 'package:luxury_app/models/order_line.dart';
import 'package:luxury_app/models/order_status.dart';
import 'package:luxury_app/models/payment_entry.dart';
import 'package:luxury_app/models/restaurant_order.dart';

/// Un pago parcial dentro de un cobro dividido (efectivo, Yape, tarjeta…).
class PaymentSplit {
  const PaymentSplit({
    required this.method,
    required this.amount,
    this.reference = '',
    this.cashReceived,
  });

  final String method;
  final double amount;
  final String reference;
  final double? cashReceived;
}

/// Cuenta por cobrar: todos los pedidos vigentes de una mesa (consumos
/// adicionales incluidos) o un único pedido de delivery / para llevar.
class AccountGroup {
  const AccountGroup(this.orders);

  /// Pedidos de la cuenta ordenados del más antiguo al más reciente.
  final List<RestaurantOrder> orders;

  RestaurantOrder get first => orders.first;
  bool get isTable => first.isTableOrder;
  String get label => isTable ? 'Mesa ${first.tableNumber}' : first.placeLabel;
  String get key => isTable ? 'mesa-${first.tableId}' : 'pedido-${first.id}';

  List<OrderLine> get lines => [for (final order in orders) ...order.lines];
  List<PaymentEntry> get payments => [
    for (final order in orders) ...order.payments,
  ];
  double get total => orders.fold(0, (sum, order) => sum + order.total);
  double get paid => orders.fold(0, (sum, order) => sum + order.paid);
  double get balance => orders.fold(0, (sum, order) => sum + order.balance);

  /// Cocina terminó todos los platillos de todos los pedidos de la cuenta.
  bool get kitchenFinished => orders.every((order) => order.kitchenFinished);
  bool get billRequested =>
      orders.any((order) => order.status == OrderStatus.forPayment);

  /// Pedido combinado para imprimir la precuenta de toda la mesa.
  RestaurantOrder get combined =>
      first.copyWith(lines: lines, payments: payments);
}
