import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/core/utils/formatters.dart';
import 'package:luxury_app/core/utils/status_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/widgets/widgets.dart';

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key, required this.store});
  final RestaurantStore store;

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _CartLine {
  _CartLine(this.item);
  final MenuItem item;
  int quantity = 1;
  String note = '';
}

class _WaiterScreenState extends State<WaiterScreen> {
  int page = 0;
  int? selectedTableId;
  int diners = 2;
  String category = 'Todas';
  final Map<int, _CartLine> cart = {};
  RestaurantOrder? editingOrder;
  int? additionalParentId;

  RestaurantStore get store => widget.store;
  RestaurantTable? get selectedTable =>
      store.tables.where((table) => table.id == selectedTableId).firstOrNull;
  double get cartTotal =>
      cart.values.fold(0, (sum, line) => sum + line.item.price * line.quantity);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  void _openOrder(
    RestaurantTable table, {
    RestaurantOrder? editOrder,
    RestaurantOrder? parentOrder,
  }) {
    setState(() {
      selectedTableId = table.id;
      editingOrder = editOrder;
      additionalParentId = parentOrder?.id;
      diners = editOrder?.diners ?? (table.capacity < 2 ? table.capacity : 2);
      cart.clear();
      if (editOrder != null) {
        for (final line in editOrder.lines) {
          final item = store.menu
              .where((value) => value.id == line.menuItemId)
              .firstOrNull;
          if (item != null) {
            cart[item.id] = _CartLine(item)
              ..quantity = line.quantity
              ..note = line.note;
          }
        }
      }
      page = 1;
    });
  }

  Future<void> _submitOrder() async {
    final table = selectedTable;
    if (table == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una mesa primero.')),
      );
      return;
    }
    await _run(() async {
      final lines = cart.values
          .map(
            (line) => OrderLine(
              menuItemId: line.item.id,
              name: line.item.name,
              quantity: line.quantity,
              unitPrice: line.item.price,
              note: line.note,
            ),
          )
          .toList();
      if (editingOrder case final existing?) {
        await store.editOrder(order: existing, lines: lines, diners: diners);
      } else {
        await store.createOrder(
          table: table,
          diners: diners,
          lines: lines,
          parentOrderId: additionalParentId,
        );
      }
      if (!mounted) return;
      final wasEditing = editingOrder != null;
      setState(() {
        cart.clear();
        editingOrder = null;
        additionalParentId = null;
        page = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Cambios del pedido guardados.'
                : 'Comanda enviada a cocina.',
          ),
        ),
      );
    });
  }

  Future<void> _tableActions(RestaurantTable table) async {
    final activeOrders = store.orders.where(
      (order) =>
          order.tableId == table.id &&
          order.status != OrderStatus.paid &&
          order.status != OrderStatus.cancelled &&
          order.status != OrderStatus.delivered,
    );
    final settledOrders = store.orders
        .where(
          (order) =>
              order.tableId == table.id &&
              (order.status == OrderStatus.paid ||
                  order.status == OrderStatus.cancelled) &&
              !order.retirementConfirmed,
        )
        .toList();
    final paidOrders = settledOrders
        .where((order) => order.status == OrderStatus.paid)
        .toList();
    final canRelease =
        settledOrders.isNotEmpty &&
        store.orders
            .where((order) => order.tableId == table.id)
            .every(
              (order) =>
                  order.status == OrderStatus.paid ||
                  order.status == OrderStatus.cancelled,
            ) &&
        settledOrders.every(
          (order) =>
              order.status != OrderStatus.paid ||
              kitchenStage(order) == OrderStatus.delivered,
        );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveListTile(
                leading: const Icon(Icons.table_restaurant, color: luxuryGold),
                title: Text('Mesa ${table.number}'),
                subtitle: Text(
                  '${table.capacity} personas · ${table.status.label}',
                ),
              ),
              ResponsiveListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Nuevo pedido'),
                onTap: () {
                  Navigator.pop(context);
                  _openOrder(table);
                },
              ),
              if (activeOrders.isNotEmpty)
                ResponsiveListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('Ver pedidos abiertos (${activeOrders.length})'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => page = 2);
                  },
                ),
              if (paidOrders.isNotEmpty)
                ResponsiveListTile(
                  leading: const Icon(Icons.add_shopping_cart),
                  title: const Text('Agregar consumo adicional'),
                  subtitle: Text('Vinculado al pedido #${paidOrders.last.id}'),
                  onTap: () {
                    Navigator.pop(context);
                    _openOrder(table, parentOrder: paidOrders.last);
                  },
                ),
              if (canRelease)
                ResponsiveListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Confirmar retiro y liberar mesa'),
                  onTap: () {
                    Navigator.pop(context);
                    _run(() => store.confirmTableRelease(table));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floor() {
    final tables = store.tables.where((table) => table.active).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionTitle(
          title: 'Mesas',
          subtitle: 'Toca una mesa para abrir el servicio',
          trailing: FilledButton.icon(
            onPressed: tables.isEmpty ? null : () => _openOrder(tables.first),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo pedido'),
          ),
        ),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _legend('Disponible', luxuryGreen),
            _legend('Ocupada', luxuryGold),
            _legend('Por cobrar', luxuryRed),
          ],
        ),
        const SizedBox(height: 14),
        if (tables.isEmpty)
          const EmptyState(
            message: 'No hay mesas activas en el salón.',
            icon: Icons.table_restaurant,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 850
                  ? 4
                  : constraints.maxWidth > 650
                  ? 3
                  : constraints.maxWidth > 360
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tables.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent:
                      205 * MediaQuery.textScalerOf(context).scale(1),
                ),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  final orderCount = store.orders
                      .where(
                        (order) =>
                            order.tableId == table.id &&
                            order.status != OrderStatus.paid &&
                            order.status != OrderStatus.cancelled &&
                            order.status != OrderStatus.delivered,
                      )
                      .length;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _tableActions(table),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: statusColor(table.status.databaseValue),
                              width: 5,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.table_restaurant,
                              color: luxuryBrown,
                            ),
                            const Spacer(),
                            Text(
                              'Mesa ${table.number}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${table.capacity} asientos · $orderCount ${orderCount == 1 ? 'pedido' : 'pedidos'}',
                            ),
                            const SizedBox(height: 8),
                            StatusBadge.table(table.status),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _legend(String label, Color color) => Chip(
    avatar: CircleAvatar(radius: 6, backgroundColor: color),
    label: Text(label),
  );

  Widget _newOrder() {
    final table = selectedTable;
    if (table == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => setState(() => page = 0),
          icon: const Icon(Icons.table_restaurant),
          label: const Text('Elegir mesa'),
        ),
      );
    }
    final categories = ['Todas', ...store.categories];
    final items = store.menu
        .where(
          (item) =>
              item.available &&
              (category == 'Todas' || item.category == category),
        )
        .toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('order-form-scroll'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: SectionTitle(
                  title:
                      '${editingOrder != null
                          ? 'Editar pedido'
                          : additionalParentId != null
                          ? 'Consumo adicional'
                          : 'Nueva comanda'} · Mesa ${table.number}',
                  subtitle: editingOrder != null
                      ? 'Solo se puede editar antes de que cocina inicie la preparación'
                      : 'Elige los platos y agrega observaciones especiales',
                  trailing: IconButton(
                    tooltip: 'Volver a mesas',
                    onPressed: () => setState(() => page = 0),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: categories
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: category == value,
                            onSelected: (_) => setState(() => category = value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Comensales'),
                    DropdownButton<int>(
                      value: diners,
                      items: List.generate(
                        table.capacity,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => diners = value ?? diners),
                    ),
                    Text('de ${table.capacity} lugares'),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 880
                      ? 3
                      : constraints.maxWidth > 580
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent:
                          156 * MediaQuery.textScalerOf(context).scale(1),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final line = cart[item.id];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: luxuryGold.withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: luxuryBrown,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      money(item.price),
                                      style: const TextStyle(
                                        color: luxuryBrown,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (line != null)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () async {
                                          final note = await _noteDialog(
                                            line.note,
                                          );
                                          if (note != null) {
                                            setState(() => line.note = note);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.edit_note,
                                          size: 18,
                                        ),
                                        label: Text(
                                          line.note.isEmpty
                                              ? 'Agregar nota'
                                              : line.note,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (line == null)
                                IconButton.filledTonal(
                                  key: ValueKey('add-menu-item-${item.id}'),
                                  onPressed: () => setState(
                                    () => cart[item.id] = _CartLine(item),
                                  ),
                                  icon: const Icon(Icons.add),
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(() {
                                        line.quantity++;
                                      }),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      '${line.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(() {
                                        line.quantity--;
                                        if (line.quantity <= 0) {
                                          cart.remove(item.id);
                                        }
                                      }),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${cart.values.fold<int>(0, (sum, line) => sum + line.quantity)} productos\n${money(cartTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                FilledButton.icon(
                  onPressed: cart.isEmpty ? null : _submitOrder,
                  icon: const Icon(Icons.send),
                  label: Text(
                    editingOrder != null
                        ? 'Guardar cambios'
                        : 'Enviar a cocina',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _noteDialog(String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observaciones del plato'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ej. Sin picante, sillao extra',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _cancelOrder(RestaurantOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
          '¿Cancelar el pedido #${order.id}? Solo se puede hacer antes de que cocina inicie y sin abonos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(() => store.cancelOrder(order));
  }

  Widget _orders({bool history = false}) {
    final orders = store.orders.where((order) {
      final finished =
          order.status == OrderStatus.cancelled ||
          (order.balance <= .001 &&
              kitchenStage(order) == OrderStatus.delivered) ||
          (order.status == OrderStatus.delivered && order.balance <= .001);
      if (history) return finished;
      return order.status != OrderStatus.cancelled && !finished;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionTitle(
          title: history ? 'Historial' : 'Mis pedidos',
          subtitle: history
              ? 'Pedidos cerrados y entregados'
              : 'Seguimiento de cocina y cuentas pendientes',
        ),
        if (orders.isEmpty)
          EmptyState(
            message: history
                ? 'Aún no hay pedidos en el historial.'
                : 'No hay pedidos abiertos.',
            icon: Icons.receipt_long,
          )
        else
          ...orders.map(
            (order) => Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: luxuryGold.withValues(alpha: .14),
                  child: Text('${order.tableNumber}'),
                ),
                title: Text('Pedido #${order.id} · Mesa ${order.tableNumber}'),
                subtitle: Text(
                  '${order.lines.fold<int>(0, (sum, line) => sum + line.quantity)} productos · ${money(order.total)}',
                ),
                trailing: StatusBadge.order(order.status),
                children: [
                  ...order.lines.map(
                    (line) => ResponsiveListTile(
                      dense: true,
                      title: Text('${line.quantity} × ${line.name}'),
                      subtitle: line.note.isEmpty ? null : Text(line.note),
                      trailing: Text(money(line.subtotal)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (order.status == OrderStatus.pending &&
                            order.payments.isEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              final table = store.tables
                                  .where((value) => value.id == order.tableId)
                                  .firstOrNull;
                              if (table != null) {
                                _openOrder(table, editOrder: order);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar pedido'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _cancelOrder(order),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar pedido'),
                          ),
                        ],
                        if (order.status == OrderStatus.ready)
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _run(() => store.advanceOrder(order)),
                            icon: const Icon(Icons.done_all),
                            label: const Text('Confirmar entrega'),
                          ),
                        if (order.status == OrderStatus.ready ||
                            order.status == OrderStatus.delivered)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _run(() => store.setOrderForPayment(order)),
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Solicitar cuenta'),
                          ),
                        if (order.balance > 0)
                          Text(
                            'Saldo ${money(order.balance)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        if (order.status == OrderStatus.paid &&
                            kitchenStage(order) == OrderStatus.delivered &&
                            !order.retirementConfirmed) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              final table = store.tables
                                  .where((value) => value.id == order.tableId)
                                  .firstOrNull;
                              if (table != null) {
                                _run(() => store.confirmTableRelease(table));
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirmar retiro de mesa'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final table = store.tables
                                  .where((value) => value.id == order.tableId)
                                  .firstOrNull;
                              if (table != null) {
                                _openOrder(table, parentOrder: order);
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Consumo adicional'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SectionTitle(title: 'Perfil', subtitle: 'Sesión de trabajo'),
      Card(
        child: ResponsiveListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(store.displayName),
          subtitle: Text(
            '${store.role?.label ?? 'Equipo'} · ${store.isConnected ? 'Supabase' : 'Demostración local'}',
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ResponsiveListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Sincronizar información'),
          subtitle: const Text(
            'Actualizar mesas, menú y pedidos desde el servicio',
          ),
          onTap: () => _run(store.refresh),
        ),
      ),
    ],
  );

  Widget _body() => switch (page) {
    0 => _floor(),
    1 => _newOrder(),
    2 => _orders(),
    3 => _orders(history: true),
    _ => _profile(),
  };

  static const _labels = [
    'Mesas',
    'Nuevo pedido',
    'Mis pedidos',
    'Historial',
    'Perfil',
  ];
  static const _icons = [
    Icons.table_restaurant,
    Icons.add_shopping_cart,
    Icons.receipt_long,
    Icons.history,
    Icons.person_outline,
  ];

  Widget _nav(bool compact) => NavigationRail(
    scrollable: true,
    selectedIndex: page,
    onDestinationSelected: (value) => setState(() => page = value),
    extended: !compact,
    labelType: compact ? NavigationRailLabelType.all : null,
    destinations: List.generate(
      _labels.length,
      (index) => NavigationRailDestination(
        icon: Icon(_icons[index]),
        selectedIcon: Icon(_icons[index], color: luxuryGold),
        label: Text(_labels[index]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      return Scaffold(
        body: Row(
          children: [
            if (!narrow) ...[
              _nav(constraints.maxWidth < 1050),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: _body()),
          ],
        ),
        bottomNavigationBar: narrow
            ? NavigationBar(
                selectedIndex: page,
                onDestinationSelected: (value) => setState(() => page = value),
                destinations: List.generate(
                  _labels.length,
                  (index) => NavigationDestination(
                    icon: Icon(_icons[index]),
                    label: _labels[index],
                  ),
                ),
              )
            : null,
      );
    },
  );
}
