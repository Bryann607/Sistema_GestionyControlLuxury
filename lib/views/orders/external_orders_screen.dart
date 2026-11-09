import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/widgets/luxury_banner.dart';
import 'package:luxury_app/widgets/luxury_feedback.dart';

/// Pedidos sin mesa. Los borradores locales NO se tratan como comandas enviadas.
/// Requiere la migración SQL incluida para sincronizar entre dispositivos.
class ExternalOrdersScreen extends StatefulWidget {
  const ExternalOrdersScreen({super.key, required this.store});
  final RestaurantStore store;
  @override
  State<ExternalOrdersScreen> createState() => _ExternalOrdersScreenState();
}

class _ExternalOrdersScreenState extends State<ExternalOrdersScreen> {
  String get _draftKey =>
      'luxury.external.pending.v1.${store.userId ?? 'demo'}';
  final List<Map<String, dynamic>> _pending = [];
  final List<Map<String, dynamic>> _remote = [];
  bool busy = false;
  String? message;
  RestaurantStore get store => widget.store;

  bool get _canManageDelivery =>
      store.role == StaffRole.cashier ||
      store.role == StaffRole.administrator ||
      store.role == StaffRole.manager;

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42P01' ||
          error.code == 'PGRST205' ||
          (error.code == 'PGRST116' &&
              error.message.toLowerCase().contains('schema cache'))) {
        return 'El módulo Delivery aún no está habilitado en Supabase. '
            'El administrador técnico debe ejecutar la migración de pedidos externos.';
      }
      if (error.code == '42501' ||
          error.code == 'PGRST301' ||
          error.message.toLowerCase().contains('row-level security')) {
        return 'Tu usuario no tiene permiso para realizar esta operación de Delivery. '
            'Solicita al administrador que revise tu rol y los permisos en Supabase.';
      }
      if (error.code == '23514' || error.code == '23502') {
        return 'Faltan datos o la modalidad no cumple las reglas del pedido. '
            'Revisa los campos e inténtalo nuevamente.';
      }
    }
    return 'No se pudo completar la operación de Delivery. '
        'Comprueba la conexión y pide al administrador que revise la configuración de Supabase.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final rows = jsonDecode(raw) as List<dynamic>;
        _pending
          ..clear()
          ..addAll(rows.map((row) => Map<String, dynamic>.from(row as Map)));
      } catch (_) {
        message = 'No se pudieron interpretar los borradores locales.';
      }
    }
    await _refresh();
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(_pending));
  }

  Future<void> _refresh() async {
    final client = store.client;
    if (client != null) {
      try {
        final query = client.from('pedidos_externos').select();
        final rows = await (store.role == StaffRole.waiter
            ? query.eq('modalidad', 'PARA_LLEVAR')
            : query).order('creado_en', ascending: false).limit(150);
        _remote
          ..clear()
          ..addAll(rows.map((row) => Map<String, dynamic>.from(row)));
        message = null;
      } catch (error) {
        message = _friendlyError(error);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    if (store.role != StaffRole.waiter &&
        store.role != StaffRole.cashier &&
        store.role != StaffRole.administrator &&
        store.role != StaffRole.manager) {
      return;
    }
    final customer = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final quantities = <int, int>{};
    var type = 'PARA_LLEVAR';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, change) {
          final total = quantities.entries.fold<double>(0, (sum, entry) {
            final item = store.menu
                .where((dish) => dish.id == entry.key)
                .firstOrNull;
            return sum + (item?.price ?? 0) * entry.value;
          });
          return AlertDialog(
            title: const Text('Nuevo pedido externo'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Modalidad'),
                      items: [
                        const DropdownMenuItem(
                          value: 'PARA_LLEVAR',
                          child: Text('Para llevar'),
                        ),
                        if (_canManageDelivery)
                          const DropdownMenuItem(
                            value: 'DELIVERY',
                            child: Text('Delivery'),
                          ),
                      ],
                      onChanged: (value) => change(() => type = value ?? type),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: customer,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del cliente',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de contacto',
                      ),
                    ),
                    if (type == 'DELIVERY') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dirección de entrega',
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Platillos',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    ...store.menu
                        .where((dish) => dish.available)
                        .map(
                          (dish) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(dish.name),
                            subtitle: Text(
                              'S/ ${dish.price.toStringAsFixed(2)}',
                            ),
                            trailing: SizedBox(
                              width: 126,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => change(() {
                                      final q = quantities[dish.id] ?? 0;
                                      if (q <= 1) {
                                        quantities.remove(dish.id);
                                      } else {
                                        quantities[dish.id] = q - 1;
                                      }
                                    }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text('${quantities[dish.id] ?? 0}'),
                                  IconButton(
                                    onPressed: () => change(
                                      () => quantities[dish.id] =
                                          (quantities[dish.id] ?? 0) + 1,
                                    ),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    const Divider(),
                    Text(
                      'Total estimado: S/ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Los borradores sin conexión no llegan a cocina hasta sincronizarlos.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (customer.text.trim().isEmpty ||
                      phone.text.trim().length != 9 ||
                      (type == 'DELIVERY' && address.text.trim().isEmpty) ||
                      quantities.isEmpty) {
                    ScaffoldMessenger.of(dialog).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ingresa el cliente, un celular de 9 dígitos, la dirección si es Delivery y al menos un platillo.',
                        ),
                      ),
                    );
                    return;
                  }
                  final lines = quantities.entries.map((entry) {
                    final dish = store.menu.firstWhere(
                      (item) => item.id == entry.key,
                    );
                    return {
                      'platillo_id': dish.id,
                      'nombre': dish.name,
                      'cantidad': entry.value,
                      'precio': dish.price,
                    };
                  }).toList();
                  Navigator.pop(dialog, {
                    'id':
                        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}',
                    'modalidad': type,
                    'cliente': customer.text.trim(),
                    'telefono': phone.text.trim(),
                    'direccion': type == 'DELIVERY' ? address.text.trim() : '',
                    'items': lines,
                    'total': total,
                    'estado': 'PENDIENTE',
                    'creado_en': DateTime.now().toUtc().toIso8601String(),
                  });
                },
                child: const Text('Guardar pedido'),
              ),
            ],
          );
        },
      ),
    );
    customer.dispose();
    phone.dispose();
    address.dispose();
    if (result == null) return;
    if (!_canManageDelivery && result['modalidad'] == 'DELIVERY') return;
    setState(() {
      _pending.add(result);
      message = null;
    });
    await _saveDrafts();
    if (store.client != null) {
      await _sync();
    } else if (mounted) {
      LuxuryFeedback.error(context, 'Pedido guardado como borrador local. No se envió a cocina.');
    }
  }

  Future<void> _sync() async {
    final client = store.client;
    if (client == null) {
      setState(
        () => message =
            'Modo demostración: los pedidos solo se guardan en este dispositivo.',
      );
      return;
    }
    if (busy) return;
    setState(() => busy = true);
    try {
      // Upsert con clave primaria fija: reintentos no generan pedidos duplicados.
      for (final draft in List<Map<String, dynamic>>.from(_pending)) {
        try {
          await client.from('pedidos_externos').insert(draft);
        } catch (error) {
          // Sólo considera sincronizado un intento repetido cuando se puede
          // verificar que el servidor ya recibió exactamente ese identificador.
          final existing = await client
              .from('pedidos_externos')
              .select('id,cliente,telefono,modalidad')
              .eq('id', draft['id'])
              .maybeSingle();
          if (existing == null ||
              existing['cliente'] != draft['cliente'] ||
              existing['telefono'] != draft['telefono'] ||
              existing['modalidad'] != draft['modalidad']) {
            rethrow;
          }
        }
        _pending.removeWhere((item) => item['id'] == draft['id']);
        await _saveDrafts();
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(
          () => message =
              '${_friendlyError(error)} '
              'El pedido permanece guardado localmente y todavía NO fue enviado a cocina.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _status(Map<String, dynamic> order, String next) async {
    if (busy || store.client == null) return;
    setState(() => busy = true);
    try {
      await store.client!.rpc(
        'actualizar_estado_pedido_externo',
        params: {'p_id': order['id'], 'p_estado': next},
      );
      await _refresh();
      if (mounted) {
        await LuxuryFeedback.success(context, title: 'Estado actualizado',
          message: 'El pedido externo cambió a ${next.toLowerCase()}.');
      }
    } catch (error) {
      if (mounted) {
        LuxuryFeedback.error(context, _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _orderCard(Map<String, dynamic> order, {required bool local}) {
    final items = (order['items'] as List<dynamic>? ?? []);
    final current = order['estado']?.toString() ?? 'PENDIENTE';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  order['modalidad'] == 'DELIVERY'
                      ? Icons.delivery_dining
                      : Icons.takeout_dining,
                  color: luxuryGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['cliente']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(label: Text(local ? 'SIN SINCRONIZAR' : current)),
              ],
            ),
            Text(order['modalidad'] == 'DELIVERY' ? 'Delivery' : 'Para llevar'),
            Text(order['telefono']?.toString() ?? ''),
            if ((order['direccion']?.toString() ?? '').isNotEmpty)
              Text('Dirección: ${order['direccion']}'),
            const Divider(),
            ...items.map(
              (item) => Text('${item['cantidad']} × ${item['nombre']}'),
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${(order['total'] as num? ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (!local &&
                store.client != null &&
                current != 'ENTREGADO' &&
                current != 'CANCELADO')
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (current == 'PENDIENTE' &&
                        (store.role == StaffRole.kitchen ||
                            store.role == StaffRole.headChef ||
                            store.role == StaffRole.administrator))
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => _status(order, 'PREPARANDO'),
                        child: const Text('Preparar'),
                      ),
                    if (current == 'PREPARANDO' &&
                        (store.role == StaffRole.kitchen ||
                            store.role == StaffRole.headChef ||
                            store.role == StaffRole.administrator))
                      OutlinedButton(
                        onPressed: busy ? null : () => _status(order, 'LISTO'),
                        child: const Text('Marcar listo'),
                      ),
                    if (current == 'LISTO' &&
                        (store.role == StaffRole.cashier ||
                            store.role == StaffRole.administrator ||
                            (store.role == StaffRole.waiter &&
                                order['modalidad'] == 'PARA_LLEVAR')))
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => _status(order, 'ENTREGADO'),
                        child: const Text('Entregado'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        store.role == StaffRole.waiter ||
        store.role == StaffRole.administrator ||
        store.role == StaffRole.manager ||
        store.role == StaffRole.cashier;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos externos'),
        actions: [
          IconButton(
            onPressed: busy ? null : _refresh,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: busy ? null : _create,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo pedido'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          LuxuryBanner(
            eyebrow: 'Más formas de atender',
            title: _canManageDelivery
                ? 'Delivery y para llevar'
                : 'Pedidos para llevar',
            description:
                'Pedidos sin mesa, seguimiento y preparación por equipo.',
            icon: Icons.delivery_dining_rounded,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(message!, style: const TextStyle(color: luxuryRed)),
            ),
          if (_pending.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pendientes locales (${_pending.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _sync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar'),
                ),
              ],
            ),
            const Text(
              'Estos pedidos todavía no están confirmados por el servidor.',
            ),
            ..._pending.map((order) => _orderCard(order, local: true)),
            const SizedBox(height: 16),
          ],
          const Text(
            'Pedidos registrados',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          if (_remote.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aún no hay pedidos externos sincronizados.'),
            ),
          ..._remote.map((order) => _orderCard(order, local: false)),
          const SizedBox(height: 75),
        ],
      ),
    );
  }
}
