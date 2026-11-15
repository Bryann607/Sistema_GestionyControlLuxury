import 'package:flutter/material.dart';

import 'package:luxury_app/core/utils/status_colors.dart';
import 'package:luxury_app/models/order_status.dart';
import 'package:luxury_app/models/table_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusBadge.order(OrderStatus status) =>
      StatusBadge(label: status.label, color: orderColor(status));

  factory StatusBadge.table(TableStatus status) => StatusBadge(
    label: status.label,
    color: statusColor(status.databaseValue),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
