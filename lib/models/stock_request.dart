class StockRequest {
  const StockRequest({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.note,
    this.status = 'PENDIENTE',
    this.priority = 'MEDIA',
    this.items = const [],
  });

  final int id;
  final String itemName;
  final double quantity;
  final String unit;
  final String note;
  final String status;
  final String priority;
  final List<StockRequestLine> items;

  StockRequest copyWith({String? status, List<StockRequestLine>? items}) =>
      StockRequest(
        id: id,
        itemName: itemName,
        quantity: quantity,
        unit: unit,
        note: note,
        status: status ?? this.status,
        priority: priority,
        items: items ?? this.items,
      );
}

class StockRequestLine {
  const StockRequestLine({
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  final String itemName;
  final double quantity;
  final String unit;
}
