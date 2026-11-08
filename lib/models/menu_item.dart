class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.available = true,
  });

  final int id;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool available;

  MenuItem copyWith({
    String? name,
    String? category,
    double? price,
    String? description,
    bool? available,
  }) => MenuItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    description: description ?? this.description,
    available: available ?? this.available,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'available': available,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as int,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String? ?? '',
    available: json['available'] as bool? ?? true,
  );
}
