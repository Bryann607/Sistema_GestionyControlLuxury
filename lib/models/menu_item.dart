class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.available = true,
  });

  final int id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final bool available;

  MenuItem copyWith({
    String? name,
    String? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? available,
  }) => MenuItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    available: available ?? this.available,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'imageUrl': imageUrl,
    'available': available,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as int,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String? ?? '',
    imageUrl: (json['imageUrl'] ?? json['foto_url']) as String? ?? '',
    available: json['available'] as bool? ?? true,
  );
}
