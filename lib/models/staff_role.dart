enum StaffRole {
  administrator('Administrador', 'ADMINISTRADOR'),
  manager('Gerente', 'GERENTE'),
  kitchen('Cocina', 'COCINERO'),
  headChef('Jefe de cocina', 'JEFE_COCINA'),
  waiter('Mesero', 'MESERO'),
  cashier('Caja', 'CAJERO');

  const StaffRole(this.label, this.databaseValue);
  final String label;
  final String databaseValue;

  static StaffRole fromDatabase(String value) => switch (value) {
    'ADMINISTRADOR' => StaffRole.administrator,
    'GERENTE' => StaffRole.manager,
    'COCINERO' => StaffRole.kitchen,
    'JEFE_COCINA' => StaffRole.headChef,
    'CAJERO' => StaffRole.cashier,
    _ => StaffRole.waiter,
  };
}
