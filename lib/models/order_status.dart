enum OrderStatus {
  pending('Pendiente', 'PENDIENTE'),
  preparing('En preparación', 'EN_PREPARACION'),
  ready('Listo', 'LISTO'),
  forPayment('Por cobrar', 'POR_COBRAR'),
  paid('Pagado', 'PAGADO'),
  delivered('Entregado', 'ENTREGADO'),
  cancelled('Cancelado', 'CANCELADO');

  const OrderStatus(this.label, this.databaseValue);
  final String label;
  final String databaseValue;

  static OrderStatus fromDatabase(String value) => switch (value) {
    'EN_PREPARACION' => OrderStatus.preparing,
    'LISTO' => OrderStatus.ready,
    'POR_COBRAR' => OrderStatus.forPayment,
    'PAGADO' => OrderStatus.paid,
    'ENTREGADO' => OrderStatus.delivered,
    'CANCELADO' => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };
}
