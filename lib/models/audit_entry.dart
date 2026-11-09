class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.entity,
    required this.entityId,
    this.actorName = 'Usuario',
    this.actorRole = '',
  });

  final int id;
  final DateTime createdAt;
  final String action;
  final String entity;
  final String entityId;
  final String actorName;
  final String actorRole;
}
