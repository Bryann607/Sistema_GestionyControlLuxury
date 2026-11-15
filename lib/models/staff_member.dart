import 'package:luxury_app/models/staff_role.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.employmentStatus = 'ACTIVO',
    this.department = '',
    this.documentId = '',
    this.personalEmail = '',
    this.phone = '',
    this.address = '',
    this.photoPath = '',
  });

  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final bool active;
  final String employmentStatus;
  final String department;
  final String documentId;
  final String personalEmail;
  final String phone;
  final String address;
  /// Ruta de la foto en Supabase Storage (bucket `employee-profiles`).
  final String photoPath;

  String get employeeCode {
    final normalized = id.replaceAll('-', '').toUpperCase();
    return 'EMP-${normalized.length > 8 ? normalized.substring(0, 8) : normalized}';
  }

  StaffMember copyWith({
    String? name,
    String? email,
    StaffRole? role,
    bool? active,
    String? employmentStatus,
    String? department,
    String? documentId,
    String? personalEmail,
    String? phone,
    String? address,
    String? photoPath,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    active: active ?? this.active,
    employmentStatus: employmentStatus ?? this.employmentStatus,
    department: department ?? this.department,
    documentId: documentId ?? this.documentId,
    personalEmail: personalEmail ?? this.personalEmail,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    photoPath: photoPath ?? this.photoPath,
  );
}
