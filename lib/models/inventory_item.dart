class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minimum,
    this.description = '',
    this.active = true,
  });

  final int id;
  final String name;
  final String unit;
  final double quantity;
  final double minimum;
  final String description;
  final bool active;
  bool get lowStock => quantity <= minimum;

  InventoryItem copyWith({
    String? name,
    String? unit,
    double? quantity,
    double? minimum,
    String? description,
    bool? active,
  }) => InventoryItem(
    id: id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    minimum: minimum ?? this.minimum,
    description: description ?? this.description,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'minimum': minimum,
    'description': description,
    'active': active,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as int,
    name: json['name'] as String,
    unit: json['unit'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    minimum: (json['minimum'] as num).toDouble(),
    description: json['description'] as String? ?? '',
    active: json['active'] as bool? ?? true,
  );
}
