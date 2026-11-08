import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/views/admin/admin_screen.dart';
import 'package:luxury_app/views/cashier/cashier_screen.dart';
import 'package:luxury_app/views/kitchen/kitchen_screen.dart';
import 'package:luxury_app/views/waiter/waiter_screen.dart';

/// Shared account navigation. Each job keeps its own operational navigation.
class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key, required this.store});
  final RestaurantStore store;

  Future<void> _resetDemo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reiniciar demostración'),
        content: const Text('Se borrarán los cambios locales de esta demostración.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reiniciar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.resetDemo();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demostración reiniciada.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')));
    }
  }

  Widget _sidebar(BuildContext context, {required bool compact}) {
    final role = store.role!;
    return Container(
      width: compact ? null : 244,
      decoration: const BoxDecoration(
        color: Color(0xFF201915),
        border: Border(right: BorderSide(color: Color(0xFF49362A))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 24),
              child: Row(children: [
                ClipOval(child: Image.asset('assets/branding/luxury_logo.png', width: 46, height: 46, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('LUXURY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('RESTAURANTE ORIENTAL', style: TextStyle(color: Color(0xFFD9AE7D), fontSize: 9, letterSpacing: 1.2)),
                ])),
              ]),
            ),
            const Divider(color: Color(0xFF49362A), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 16, 8),
              child: Text('ESPACIO DE TRABAJO', style: TextStyle(
                color: Colors.white.withValues(alpha: .45), fontWeight: FontWeight.w700,
                fontSize: 10, letterSpacing: 1.6)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined, color: luxuryGold),
                title: Text(role.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Panel principal', style: TextStyle(color: Colors.white54, fontSize: 12)),
                selected: true,
                selectedTileColor: const Color(0xFF443024),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: compact ? () => Navigator.pop(context) : null,
              ),
            ),
            const Spacer(),
            const Divider(color: Color(0xFF49362A), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFF64452D), child: Icon(Icons.person_outline, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(role.label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ])),
              ]),
            ),
            if (store.isDemo)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.restart_alt, color: Colors.white70),
                title: const Text('Reiniciar demostración', style: TextStyle(color: Colors.white70)),
                onTap: () { if (compact) Navigator.pop(context); unawaited(_resetDemo(context)); },
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFF3A575)),
              title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFF3A575), fontWeight: FontWeight.w700)),
              onTap: () => unawaited(store.signOut()),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = store.role!;
    final compact = MediaQuery.sizeOf(context).width < 1050;
    final content = switch (role) {
      StaffRole.administrator => AdminScreen(store: store),
      StaffRole.manager => AdminScreen(store: store, managerOnly: true),
      StaffRole.kitchen => KitchenScreen(store: store),
      StaffRole.headChef => KitchenScreen(store: store),
      StaffRole.waiter => WaiterScreen(store: store),
      StaffRole.cashier => CashierScreen(store: store),
    };
    return Scaffold(
      drawer: compact ? Drawer(width: 278, child: _sidebar(context, compact: true)) : null,
      appBar: compact ? AppBar(
        title: Text('LUXURY · ${role.label}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
        backgroundColor: const Color(0xFF201915),
      ) : null,
      body: Row(children: [
        if (!compact) _sidebar(context, compact: false),
        Expanded(child: content),
      ]),
    );
  }
}
