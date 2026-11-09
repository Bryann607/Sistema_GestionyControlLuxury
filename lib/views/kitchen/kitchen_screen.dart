import 'package:luxury_app/widgets/luxury_feedback.dart';
import 'package:luxury_app/widgets/luxury_banner.dart';
import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/core/utils/status_colors.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/widgets/widgets.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key, required this.store, this.navigationController});
  final RestaurantStore store;
  final ValueNotifier<int>? navigationController;

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  int _page = 0;
  int get page => _page;
  set page(int value) {
    _page = value;
    final controller = widget.navigationController;
    if (controller != null && controller.value != value) {
      controller.value = value;
    }
  }

  void _onNavigationChange() {
    final value = widget.navigationController?.value;
    if (value != null && value != _page && mounted) {
      setState(() => _page = value);
    }
  }

  @override
  void initState() {
    super.initState();
    _page = widget.navigationController?.value ?? 0;
    widget.navigationController?.addListener(_onNavigationChange);
  }

  @override
  void didUpdateWidget(covariant KitchenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationController != widget.navigationController) {
      oldWidget.navigationController?.removeListener(_onNavigationChange);
      widget.navigationController?.addListener(_onNavigationChange);
      _page = widget.navigationController?.value ?? _page;
    }
  }

  @override
  void dispose() {
    widget.navigationController?.removeListener(_onNavigationChange);
    super.dispose();
  }

  String query = '';
  bool notesOnly = false;
  RestaurantStore get store => widget.store;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        LuxuryFeedback.error(context, LuxuryFeedback.message(error));
      }
    }
  }

  Future<void> _reportIncident(RestaurantOrder order) async {
    final controller = TextEditingController(text: order.incident);
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Incidencia · Pedido #${order.id}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 240,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Describe el problema del pedido',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Registrar incidencia'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null) {
      await _run(() => store.reportKitchenIncident(order, reason));
    }
  }

  Future<void> _createAlert() async {
    final message = TextEditingController();
    InventoryItem? selectedItem = store.inventory
        .where((item) => item.active && item.lowStock)
        .firstOrNull;
    final result = await showDialog<(InventoryItem?, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aviso de cocina'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<InventoryItem?>(
                  initialValue: selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Insumo relacionado (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem<InventoryItem?>(
                      value: null,
                      child: Text('Aviso general'),
                    ),
                    ...store.inventory
                        .where((item) => item.active)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedItem = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo insumo a solicitar o detalle del faltante',
                    helperText: 'El aviso no registra un insumo nuevo en inventario.',
                    helperMaxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (selectedItem, message.text.trim())),
              child: const Text('Enviar a administración'),
            ),
          ],
        ),
      ),
    );
    message.dispose();
    if (result != null) {
      await _run(
        () => store.createKitchenAlert(item: result.$1, message: result.$2),
      );
    }
  }

  Future<void> _requestStock(InventoryItem item) async {
    final quantity = TextEditingController(
      text: (item.minimum * 2).toStringAsFixed(1),
    );
    final note = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Solicitar ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'Cantidad (${item.unit})'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observación'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (quantity.text, note.text)),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    quantity.dispose();
    note.dispose();
    if (result != null) {
      await _run(() async {
        final amount = double.tryParse(result.$1);
        if (amount == null) {
          throw StateError('Escribe una cantidad válida.');
        }
        await store.createStockRequest(item, amount, result.$2);
      });
    }
  }

  Widget _board() {
    final active =
        store.orders
            .where(
              (order) =>
                  order.status != OrderStatus.cancelled &&
                  kitchenStage(order) != OrderStatus.delivered,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final visible = active.where((order) {
      final hasNotes =
          !notesOnly || order.lines.any((line) => line.note.isNotEmpty);
      final text =
          'mesa ${order.tableNumber} ${order.id} ${order.lines.map((line) => line.name).join(' ')}'
              .toLowerCase();
      return hasNotes && text.contains(query);
    }).toList();
    final lanes = [
      (OrderStatus.pending, 'Nuevas comandas'),
      (OrderStatus.preparing, 'En preparación'),
      (OrderStatus.ready, 'Listas para servir'),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const LuxuryBanner(eyebrow: 'Cocina en movimiento', title: 'Comandas en preparación',
          description: 'Visualiza los pedidos, coordina el equipo y mantiene el ritmo del servicio.',
          icon: Icons.soup_kitchen_rounded),
        SectionTitle(
          title: 'Comandas de cocina',
          subtitle:
              'Actualización en vivo · Respeta las observaciones del mesero',
          trailing: Wrap(
            children: [
              if (store.isDemo)
                IconButton(
                  tooltip: 'Pedido de prueba',
                  onPressed: () {
                    final table = store.tables
                        .where((value) => value.status == TableStatus.available)
                        .firstOrNull;
                    final item = store.menu
                        .where((value) => value.available)
                        .firstOrNull;
                    if (table == null || item == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No hay una mesa disponible o un plato habilitado.',
                          ),
                        ),
                      );
                      return;
                    }
                    _run(
                      () => store.createOrder(
                        table: table,
                        diners: 1,
                        lines: [
                          OrderLine(
                            menuItemId: item.id,
                            name: item.name,
                            quantity: 1,
                            unitPrice: item.price,
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_box_outlined),
                ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () => _run(store.refresh),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar mesa, pedido o plato',
              ),
              onChanged: (value) =>
                  setState(() => query = value.toLowerCase().trim()),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Con observaciones'),
              selected: notesOnly,
              onSelected: (value) => setState(() => notesOnly = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          const EmptyState(
            message: 'No hay comandas pendientes.',
            icon: Icons.check_circle_outline,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 980;
              if (horizontal) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lanes
                      .map(
                        (lane) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _lane(
                              lane.$1,
                              lane.$2,
                              visible
                                  .where(
                                    (order) => kitchenStage(order) == lane.$1,
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: lanes
                    .map(
                      (lane) => _lane(
                        lane.$1,
                        lane.$2,
                        visible
                            .where((order) => kitchenStage(order) == lane.$1)
                            .toList(),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _lane(
    OrderStatus status,
    String title,
    List<RestaurantOrder> orders,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              CircleAvatar(
                radius: 13,
                backgroundColor: orderColor(status).withValues(alpha: .16),
                child: Text(
                  '${orders.length}',
                  style: TextStyle(color: orderColor(status), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sin pedidos',
                style: TextStyle(color: Colors.black45),
              ),
            )
          else
            ...orders.map((order) => _ticket(order)),
        ],
      ),
    ),
  );

  Widget _ticket(RestaurantOrder order) {
    final elapsed = DateTime.now().difference(order.createdAt).inMinutes;
    final nextAction = switch (kitchenStage(order)) {
      OrderStatus.pending => 'Iniciar preparación',
      OrderStatus.preparing => 'Marcar listo',
      OrderStatus.ready => 'Entregar al mesero',
      _ => '',
    };
    return Card(
      color: luxuryBone,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mesa ${order.tableNumber} · #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${elapsed}m',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: elapsed >= 20 ? luxuryRed : luxuryBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.createdAt.toLocal().toString().substring(11, 16),
              style: const TextStyle(color: Colors.black54),
            ),
            if (order.status == OrderStatus.paid)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: StatusBadge(
                  label: 'PAGADO · CONTINÚA EN COCINA',
                  color: luxuryGreen,
                ),
              ),
            if (order.status == OrderStatus.forPayment)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: StatusBadge(
                  label: 'CUENTA SOLICITADA',
                  color: luxuryRed,
                ),
              ),
            if (order.incident.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ErrorBanner(message: 'Incidencia: ${order.incident}'),
              ),
            const Divider(),
            ...order.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${line.quantity}×',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (line.note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                line.note,
                                style: const TextStyle(
                                  color: luxuryRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _run(() async {
                  await store.advanceOrder(order);
                  if (mounted) {
                    await LuxuryFeedback.success(context,
                      title: 'Comanda actualizada',
                      message: 'El estado del pedido #${order.id} se actualizó correctamente.');
                  }
                }),
                child: Text(nextAction),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _reportIncident(order),
                icon: const Icon(Icons.report_problem_outlined, size: 18),
                label: const Text('Reportar incidencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kitchenInventory() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      SectionTitle(
        title: 'Insumos y disponibilidad',
        subtitle: 'Comunica faltantes y bloquea platos agotados',
        trailing: FilledButton.tonalIcon(
          onPressed: _createAlert,
          icon: const Icon(Icons.notification_add_outlined),
          label: const Text('Aviso de bajo stock'),
        ),
      ),
      ...store.inventory
          .where((item) => item.active)
          .map(
            (item) => Card(
              child: ResponsiveListTile(
                leading: Icon(
                  item.lowStock
                      ? Icons.warning_amber
                      : Icons.inventory_2_outlined,
                  color: item.lowStock ? luxuryRed : luxuryBrown,
                ),
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} ${item.unit} · mínimo ${item.minimum}',
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Avisar a administración',
                      onPressed: () => _run(
                        () => store.createKitchenAlert(
                          item: item,
                          message: 'Bajo stock: ${item.name}',
                        ),
                      ),
                      icon: const Icon(Icons.notification_add_outlined),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _requestStock(item),
                      child: const Text('Solicitar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      const SizedBox(height: 14),
      Text('Alertas recientes', style: Theme.of(context).textTheme.titleMedium),
      ...store.alerts
          .where((alert) => alert.status == 'NUEVA')
          .map(
            (alert) => ResponsiveListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: luxuryRed,
              ),
              title: Text(alert.message),
              subtitle: Text('${alert.priority} · enviada a administración'),
            ),
          ),
      const SizedBox(height: 14),
      Text(
        'Disponibilidad en carta',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      ...store.menu.map(
        (item) => SwitchListTile(
          value: item.available,
          title: Text(item.name),
          subtitle: Text(
            item.available ? 'Disponible para comandas' : 'Agotado',
          ),
          onChanged: (value) =>
              _run(() => store.setMenuAvailability(item, value)),
        ),
      ),
    ],
  );

  Widget _kitchenHistory() {
    final history = store.orders
        .where(
          (order) =>
              order.status == OrderStatus.cancelled ||
              kitchenStage(order) == OrderStatus.delivered,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle(
          title: 'Historial de cocina',
          subtitle: 'Comandas entregadas o cerradas',
        ),
        if (history.isEmpty)
          const EmptyState(message: 'Todavía no hay comandas cerradas.')
        else
          ...history.map(
            (order) => Card(
              child: ResponsiveListTile(
                leading: const Icon(Icons.done_all),
                title: Text('Mesa ${order.tableNumber} · #${order.id}'),
                subtitle: Text(
                  order.lines
                      .map((line) => '${line.quantity}× ${line.name}')
                      .join(', '),
                ),
                trailing: StatusBadge.order(order.status),
              ),
            ),
          ),
      ],
    );
  }

  static const _labels = ['Comandas', 'Insumos y carta', 'Historial'];
  static const _icons = [
    Icons.soup_kitchen_outlined,
    Icons.inventory_2_outlined,
    Icons.history,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final body = switch (page) {
        0 => _board(),
        1 => _kitchenInventory(),
        _ => _kitchenHistory(),
      };
      return Scaffold(
        body: Row(
          children: [
            if (!narrow && widget.navigationController == null) ...[
              NavigationRail(
                scrollable: true,
                selectedIndex: page,
                onDestinationSelected: (value) => setState(() => page = value),
                extended: constraints.maxWidth > 1040,
                labelType: constraints.maxWidth > 1040
                    ? null
                    : NavigationRailLabelType.all,
                destinations: List.generate(
                  _labels.length,
                  (index) => NavigationRailDestination(
                    icon: Icon(_icons[index]),
                    label: Text(_labels[index]),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: narrow && widget.navigationController == null
            ? NavigationBar(
                height: MediaQuery.sizeOf(context).height < 500 ? 64 : 80,
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
