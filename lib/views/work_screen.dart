import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/views/admin/admin_screen.dart';
import 'package:luxury_app/views/cashier/cashier_screen.dart';
import 'package:luxury_app/views/kitchen/kitchen_screen.dart';
import 'package:luxury_app/views/waiter/waiter_screen.dart';
import 'package:luxury_app/views/orders/external_orders_screen.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key, required this.store});
  final RestaurantStore store;

  Future<void> _resetDemo(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Reiniciar demostración'),
      content: const Text('Esto elimina los cambios locales de la demostración. No afecta la base de datos remota.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Reiniciar'))],
    ));
    if (confirm != true) return;
    try {
      await store.resetDemo();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demostración restablecida.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')));
    }
  }

  Widget _identity() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 14, 22),
    child: Row(children: [
      ClipOval(child: Image.asset('assets/branding/luxury_logo.png', width: 49, height: 49, fit: BoxFit.cover)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LUXURY', style: TextStyle(color: Colors.white, fontSize: 21,
          letterSpacing: 2, fontWeight: FontWeight.w900)),
        Text('RESTAURANTE ORIENTAL', style: TextStyle(color: Color(0xFFEFAC67),
          fontSize: 9, letterSpacing: 1.05, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );

  Widget _sidebar(BuildContext context, {required bool compact}) {
    final role = store.role!;
    return Container(
      width: compact ? null : 258,
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF181B1D), Color(0xFF2B1B17)])),
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _identity(),
        const Divider(color: Color(0xFF574139), height: 1),
        const Padding(padding: EdgeInsets.fromLTRB(24, 25, 16, 10), child: Text(
          'ESPACIO DE TRABAJO', style: TextStyle(color: Color(0xFFB7A6A0),
          fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Container(
          decoration: BoxDecoration(color: const Color(0xFF5D3927), borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: luxuryGold),
            title: Text(role.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            subtitle: const Text('Panel de operaciones', style: TextStyle(color: Color(0xFFD5C7C0), fontSize: 12)),
            onTap: compact ? () => Navigator.pop(context) : null,
          ),
        )),
        const Padding(padding: EdgeInsets.fromLTRB(24, 20, 24, 0), child: Text(
          'Utiliza las secciones del panel para gestionar el servicio.',
          style: TextStyle(color: Color(0xFFBEB2AC), fontSize: 12, height: 1.5))),
        Padding(padding: const EdgeInsets.fromLTRB(12, 14, 12, 0), child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.delivery_dining_rounded, color: luxuryGold),
          title: const Text('Delivery y para llevar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: const Text('Pedidos sin mesa', style: TextStyle(color: Colors.white60, fontSize: 11)),
          onTap: () {
            if (compact) Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
              ExternalOrdersScreen(store: store)));
          },
        )),
        const Spacer(),
        const Divider(color: Color(0xFF574139), height: 1),
        Padding(padding: const EdgeInsets.fromLTRB(17, 15, 14, 12), child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFF73492D),
            child: Icon(Icons.person_rounded, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(role.label, style: const TextStyle(color: Color(0xFFC9ADA0), fontSize: 12)),
          ])),
        ])),
        if (store.isDemo) ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 22),
          leading: const Icon(Icons.restart_alt, color: Colors.white70),
          title: const Text('Reiniciar demostración', style: TextStyle(color: Colors.white70)),
          onTap: () { if (compact) Navigator.pop(context); unawaited(_resetDemo(context)); },
        ),
        Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 10), child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF49302B),
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFFFAC7C)),
          title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFFFC19D),
            fontWeight: FontWeight.w800)),
          onTap: () => unawaited(store.signOut()),
        )),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = store.role!;
    final compact = MediaQuery.sizeOf(context).width < 1080;
    final content = switch (role) {
      StaffRole.administrator => AdminScreen(store: store),
      StaffRole.manager => AdminScreen(store: store, managerOnly: true),
      StaffRole.kitchen => KitchenScreen(store: store),
      StaffRole.headChef => KitchenScreen(store: store),
      StaffRole.waiter => WaiterScreen(store: store),
      StaffRole.cashier => CashierScreen(store: store),
    };
    return Scaffold(
      drawer: compact ? Drawer(width: 286, child: _sidebar(context, compact: true)) : null,
      appBar: compact ? AppBar(
        title: Text('LUXURY  ·  ${role.label}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: .5)),
        actions: [Builder(builder: (context) => IconButton(
          tooltip: 'Menú de cuenta', icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ))],
      ) : null,
      body: Row(children: [
        if (!compact) _sidebar(context, compact: false),
        Expanded(child: content),
      ]),
    );
  }
}
