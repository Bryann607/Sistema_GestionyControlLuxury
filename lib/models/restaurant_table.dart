import 'package:luxury_app/models/table_status.dart';

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
    this.active = true,
  });

  final int id;
  final int number;
  final int capacity;
  final TableStatus status;
  final bool active;

  RestaurantTable copyWith({
    int? number,
    int? capacity,
    TableStatus? status,
    bool? active,
  }) => RestaurantTable(
    id: id,
    number: number ?? this.number,
    capacity: capacity ?? this.capacity,
    status: status ?? this.status,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'capacity': capacity,
    'status': status.databaseValue,
    'active': active,
  };

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'] as int,
        number: json['number'] as int,
        capacity: json['capacity'] as int,
        status: TableStatus.fromDatabase(json['status'] as String),
        active: json['active'] as bool? ?? true,
      );
}
