enum TableStatus {
  available('Disponible', 'DISPONIBLE'),
  occupied('Ocupada', 'OCUPADA'),
  payment('Por cobrar', 'POR_COBRAR');

  const TableStatus(this.label, this.databaseValue);
  final String label;
  final String databaseValue;

  static TableStatus fromDatabase(String value) => switch (value) {
    'OCUPADA' => TableStatus.occupied,
    'POR_COBRAR' => TableStatus.payment,
    _ => TableStatus.available,
  };
}
