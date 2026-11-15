class StockAlert {
  const StockAlert({
    required this.id,
    required this.message,
    required this.createdAt,
    this.inventoryId,
    this.status = 'NUEVA',
    this.priority = 'MEDIA',
  });

  final int id;
  final String message;
  final DateTime createdAt;
  final int? inventoryId;
  final String status;
  final String priority;

  StockAlert copyWith({String? status, String? priority}) => StockAlert(
    id: id,
    message: message,
    createdAt: createdAt,
    inventoryId: inventoryId,
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'inventoryId': inventoryId,
    'status': status,
    'priority': priority,
  };

  factory StockAlert.fromJson(Map<String, dynamic> json) => StockAlert(
    id: json['id'] as int,
    message: json['message'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    inventoryId: json['inventoryId'] as int?,
    status: json['status'] as String,
    priority: json['priority'] as String,
  );
}
