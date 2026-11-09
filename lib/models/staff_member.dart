import 'package:luxury_app/models/staff_role.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final bool active;

  StaffMember copyWith({
    String? name,
    String? email,
    StaffRole? role,
    bool? active,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    active: active ?? this.active,
  );
}
