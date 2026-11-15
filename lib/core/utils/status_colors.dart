import 'package:flutter/material.dart';

import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/models/order_status.dart';

Color statusColor(String status) => switch (status) {
  'DISPONIBLE' || 'LISTO' || 'PAGADO' || 'ATENDIDO' => luxuryGreen,
  'POR_COBRAR' || 'CANCELADO' => luxuryRed,
  _ => luxuryGold,
};

Color orderColor(OrderStatus status) => statusColor(status.databaseValue);
