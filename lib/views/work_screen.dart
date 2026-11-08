import 'dart:async';

import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/views/admin/admin_screen.dart';
import 'package:luxury_app/views/cashier/cashier_screen.dart';
import 'package:luxury_app/views/kitchen/kitchen_screen.dart';
import 'package:luxury_app/views/waiter/waiter_screen.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key, required this.store});
  final RestaurantStore store;

  Future<void> _resetDemo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar demostración'),
        content: const Text(
          'Se eliminarán los cambios locales y volverán los datos de ejemplo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await store.resetDemo();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demostración reiniciada.')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = store.role!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: luxuryGold),
            const SizedBox(width: 10),
            const Text(
              'LUXURY',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(width: 12),
            if (MediaQuery.sizeOf(context).width > 650)
              Text(
                '· ${role.label}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width > 600)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Chip(
                avatar: Icon(
                  store.isConnected ? Icons.cloud_done : Icons.wifi_off,
                  size: 17,
                ),
                label: Text(store.isConnected ? 'Supabase' : 'Demo local'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          PopupMenuButton<String>(
            tooltip: store.displayName,
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') unawaited(store.signOut());
              if (value == 'reset') unawaited(_resetDemo(context));
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                value: 'account',
                child: Text('${store.displayName}\n${role.label}'),
              ),
              if (store.isDemo)
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Reiniciar demostración'),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (role) {
        StaffRole.administrator => AdminScreen(store: store),
        StaffRole.manager => AdminScreen(store: store, managerOnly: true),
        StaffRole.kitchen => KitchenScreen(store: store),
        StaffRole.headChef => KitchenScreen(store: store),
        StaffRole.waiter => WaiterScreen(store: store),
        StaffRole.cashier => CashierScreen(store: store),
      },
    );
  }
}
