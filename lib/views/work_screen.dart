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

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key, required this.store});
  final RestaurantStore store;

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final ValueNotifier<int> _section = ValueNotifier<int>(0);
  RestaurantStore get store => widget.store;

  @override
  void dispose() {
    _section.dispose();
    super.dispose();
  }

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

  static const _adminLabels = [
    'Resumen', 'Menú y catálogo', 'Inventario', 'Usuarios y roles',
    'Mesas', 'Reportes', 'Incidencias', 'Auditoría',
  ];
  static const _adminIcons = [
    Icons.dashboard_outlined, Icons.restaurant_menu, Icons.inventory_2_outlined,
    Icons.groups_outlined, Icons.table_restaurant, Icons.bar_chart,
    Icons.report_problem_outlined, Icons.history,
  ];
  static const _managerLabels = [
    'Resumen', 'Usuarios', 'Mesas', 'Incidencias', 'Reportes', 'Auditoría',
  ];
  static const _managerIcons = [
    Icons.dashboard_outlined, Icons.groups_outlined, Icons.table_restaurant,
    Icons.report_problem_outlined, Icons.bar_chart, Icons.history,
  ];
  static const _waiterLabels = [
    'Mesas', 'Nuevo pedido', 'Mis pedidos', 'Historial', 'Perfil',
  ];
  static const _waiterIcons = [
    Icons.table_restaurant, Icons.add_shopping_cart, Icons.receipt_long,
    Icons.history, Icons.person_outline,
  ];
  static const _kitchenLabels = ['Comandas', 'Insumos y carta', 'Historial'];
  static const _kitchenIcons = [
    Icons.soup_kitchen_outlined, Icons.inventory_2_outlined, Icons.history,
  ];
  static const _cashierLabels = [
    'Cuentas y cobros', 'Notas de venta', 'Arqueo de caja', 'Actividad',
  ];
  static const _cashierIcons = [
    Icons.payments_outlined, Icons.receipt_long, Icons.point_of_sale, Icons.history,
  ];

  (List<String>, List<IconData>) _menuForRole(StaffRole role) => switch (role) {
    StaffRole.administrator => (_adminLabels, _adminIcons),
    StaffRole.manager => (_managerLabels, _managerIcons),
    StaffRole.waiter => (_waiterLabels, _waiterIcons),
    StaffRole.kitchen || StaffRole.headChef => (_kitchenLabels, _kitchenIcons),
    StaffRole.cashier => (_cashierLabels, _cashierIcons),
  };

  void _selectSection(BuildContext context, int section, bool compact) {
    _section.value = section;
    if (compact) Navigator.of(context).pop();
  }

  Widget _sidebar(BuildContext context, {required bool compact}) {
    final role = store.role!;
    final (labels, icons) = _menuForRole(role);
    return Container(
      width: compact ? null : 256,
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF261910), Color(0xFF432719)])),
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _identity(),
        const Divider(color: Color(0xFF76503B), height: 1),
        const Padding(padding: EdgeInsets.fromLTRB(22, 16, 14, 6), child: Text(
          'MENÚ PRINCIPAL', style: TextStyle(color: Color(0xFFE9B58C),
            fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w800))),
        Expanded(child: AnimatedBuilder(
          animation: _section,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(padding: const EdgeInsets.only(bottom: 3), child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: _section.value == i ? const Color(0xFF805034) : null,
                  leading: Icon(icons[i], size: 21,
                    color: _section.value == i ? const Color(0xFFFFD6A0) : const Color(0xFFE7C9AF)),
                  title: Text(labels[i], style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: _section.value == i ? FontWeight.w800 : FontWeight.w500)),
                  onTap: () => _selectSection(context, i, compact),
                )),
              const Divider(color: Color(0xFF76503B), height: 22),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.delivery_dining_rounded, color: Color(0xFFFFC783)),
                title: const Text('Delivery y para llevar',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                onTap: () {
                  if (compact) Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ExternalOrdersScreen(store: store)));
                },
              ),
            ],
          ),
        )),
        const Divider(color: Color(0xFF76503B), height: 1),
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 12, 6), child: Row(children: [
          const CircleAvatar(radius: 19, backgroundColor: Color(0xFF805034),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            Text(role.label, style: const TextStyle(color: Color(0xFFE8B58F), fontSize: 12)),
          ])),
        ])),
        if (store.isDemo) ListTile(
          dense: true,
          leading: const Icon(Icons.restart_alt, color: Colors.white70),
          title: const Text('Reiniciar demostración', style: TextStyle(color: Colors.white70, fontSize: 13)),
          onTap: () {
            if (compact) Navigator.of(context).pop();
            unawaited(_resetDemo(context));
          },
        ),
        Padding(padding: const EdgeInsets.fromLTRB(10, 2, 10, 12), child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF60362C),
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFFFB58A)),
          title: const Text('Cerrar sesión', style: TextStyle(
            color: Color(0xFFFFD1B4), fontSize: 13, fontWeight: FontWeight.w800)),
          onTap: () => unawaited(store.signOut()),
        )),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = store.role!;
    // En pantallas estrechas el único menú lateral se convierte en cajón.
    final compact = MediaQuery.sizeOf(context).width < 950;
    final content = switch (role) {
      StaffRole.administrator => AdminScreen(store: store, navigationController: _section),
      StaffRole.manager => AdminScreen(store: store, managerOnly: true, navigationController: _section),
      StaffRole.kitchen => KitchenScreen(store: store, navigationController: _section),
      StaffRole.headChef => KitchenScreen(store: store, navigationController: _section),
      StaffRole.waiter => WaiterScreen(store: store, navigationController: _section),
      StaffRole.cashier => CashierScreen(store: store, navigationController: _section),
    };
    return Scaffold(
      drawer: compact ? Drawer(width: 286, child: _sidebar(context, compact: true)) : null,
      appBar: compact ? AppBar(
        title: Text('LUXURY  ·  ${role.label}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ) : null,
      body: Row(children: [
        if (!compact) _sidebar(context, compact: false),
        Expanded(child: content),
      ]),
    );
  }
}
