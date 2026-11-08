import 'package:luxury_app/widgets/luxury_banner.dart';
import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/core/utils/formatters.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/services/receipt_pdf.dart';
import 'package:luxury_app/widgets/widgets.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key, required this.store, this.navigationController});
  final RestaurantStore store;
  final ValueNotifier<int>? navigationController;

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
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
  void didUpdateWidget(covariant CashierScreen oldWidget) {
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

  String method = 'Efectivo';
  RestaurantStore get store => widget.store;

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

  Future<void> _collect(RestaurantOrder order) async {
    if (!store.shiftOpen) {
      setState(() => page = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre el turno de caja antes de registrar pagos.'),
        ),
      );
      return;
    }
    final amount = TextEditingController(
      text: order.balance.toStringAsFixed(2),
    );
    final reference = TextEditingController();
    final received = TextEditingController(
      text: order.balance.toStringAsFixed(2),
    );
    var selectedMethod = 'Efectivo';
    final requiresEarlyConfirmation =
        kitchenStage(order) == OrderStatus.pending ||
        kitchenStage(order) == OrderStatus.preparing;
    var earlyPaymentConfirmed = !requiresEarlyConfirmation;
    final result = await showDialog<(String, String, String, String, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Cobrar · Pedido #${order.id}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ${money(order.total)} · Pagado ${money(order.paid)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (requiresEarlyConfirmation) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: earlyPaymentConfirmed,
                    onChanged: (value) => setDialogState(
                      () => earlyPaymentConfirmed = value ?? false,
                    ),
                    title: const Text(
                      'El cliente solicita pagar antes de terminar la preparación',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                  ),
                  items:
                      const [
                            'Efectivo',
                            'Yape',
                            'Plin',
                            'Yape / Plin',
                            'Tarjeta',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setDialogState(
                    () => selectedMethod = value ?? selectedMethod,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: 'S/ ',
                    helperText: 'Saldo pendiente ${money(order.balance)}',
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedMethod == 'Efectivo')
                  TextField(
                    controller: received,
                    onChanged: (_) => setDialogState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Efectivo recibido',
                      prefixText: 'S/ ',
                    ),
                  )
                else
                  TextField(
                    controller: reference,
                    decoration: const InputDecoration(
                      labelText: 'N.º de operación / referencia',
                    ),
                  ),
                if (selectedMethod == 'Efectivo') ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final paidAmount = double.tryParse(amount.text) ?? 0;
                      final cashAmount = double.tryParse(received.text) ?? 0;
                      final change = (cashAmount - paidAmount)
                          .clamp(0, double.infinity)
                          .toDouble();
                      return Text('Vuelto: ${money(change)}');
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: earlyPaymentConfirmed
                  ? () => Navigator.pop(context, (
                      selectedMethod,
                      amount.text,
                      reference.text,
                      received.text,
                      earlyPaymentConfirmed,
                    ))
                  : null,
              child: const Text('Registrar abono'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await _run(() async {
        final value = double.tryParse(result.$2);
        if (value == null) throw StateError('Escribe un monto válido.');
        final receivedAmount = result.$1 == 'Efectivo'
            ? double.tryParse(result.$4)
            : null;
        await store.recordPayment(
          order: order,
          method: result.$1,
          amount: value,
          reference: result.$3,
          cashReceived: receivedAmount,
          earlyPaymentConfirmed: result.$5,
        );
      });
    }
    amount.dispose();
    reference.dispose();
    received.dispose();
  }

  Widget _accounts() {
    final active =
        store.orders
            .where(
              (order) =>
                  order.balance > .001 && order.status != OrderStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const LuxuryBanner(eyebrow: 'Cobros y servicio', title: 'Caja y precuentas',
          description: 'Consulta cada consumo antes de registrar un pago.',
          icon: Icons.receipt_long_rounded),
        SectionTitle(
          title: 'Cuentas y cobros',
          subtitle: 'Admite abonos y pagos mixtos por pedido',
        ),
        if (active.isEmpty)
          const EmptyState(
            message: 'No hay cuentas pendientes de pago.',
            icon: Icons.task_alt,
          )
        else
          ...active.map(
            (order) => Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: luxuryGold.withValues(alpha: .14),
                  child: Text('${order.tableNumber}'),
                ),
                title: Text('Mesa ${order.tableNumber} · Pedido #${order.id}'),
                subtitle: Text(
                  '${order.lines.length} productos · Total ${money(order.total)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Saldo', style: TextStyle(fontSize: 11)),
                    Text(
                      money(order.balance),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: luxuryRed,
                      ),
                    ),
                  ],
                ),
                children: [
                  ...order.lines.map(
                    (line) => ResponsiveListTile(
                      dense: true,
                      title: Text('${line.quantity} × ${line.name}'),
                      subtitle: line.note.isEmpty ? null : Text(line.note),
                      trailing: Text(money(line.subtotal)),
                    ),
                  ),
                  if (order.payments.isNotEmpty)
                    ...order.payments.map(
                      (payment) => ResponsiveListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: luxuryGreen,
                        ),
                        title: Text(payment.method),
                        trailing: Text(money(payment.amount)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: OutlinedButton.icon(
                      onPressed: () => _run(() => printPreBillPdf(order)),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Ver / imprimir precuenta (sin cobrar)'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _collect(order),
                        icon: const Icon(Icons.point_of_sale),
                        label: Text(
                          order.paid > 0
                              ? 'Registrar siguiente abono · ${money(order.balance)}'
                              : 'Cobrar cuenta · ${money(order.balance)}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _receipts() {
    final receipts = [...store.receipts];
    final paidOrders = store.orders
        .where((order) => order.status == OrderStatus.paid)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle(
          title: 'Notas de venta',
          subtitle: 'Comprobantes registrados en el turno',
        ),
        if (receipts.isEmpty && paidOrders.isEmpty)
          const EmptyState(
            message: 'Todavía no hay notas de venta emitidas.',
            icon: Icons.receipt_long,
          )
        else ...[
          ...receipts.map(
            (receipt) => Card(
              child: ResponsiveListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(
                  '${receipt['code']} · Mesa ${receipt['tableNumber']}',
                ),
                subtitle: Text(
                  'Pedido #${receipt['orderId']} · ${receipt['createdAt']}',
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money((receipt['total'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Imprimir nota',
                      onPressed: () => _printReceipt(receipt),
                      icon: const Icon(Icons.print_outlined),
                    ),
                    if (receipt['status'] == 'ANULADO')
                      const StatusBadge(label: 'Anulada', color: luxuryRed),
                  ],
                ),
              ),
            ),
          ),
          ...paidOrders
              .where(
                (order) =>
                    !receipts.any((receipt) => receipt['orderId'] == order.id),
              )
              .map(
                (order) => Card(
                  child: ResponsiveListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Nota de venta · Pedido #${order.id}'),
                    subtitle: Text(
                      'Mesa ${order.tableNumber} · ${order.payments.map((payment) => payment.method).toSet().join(', ')}',
                    ),
                    trailing: Text(
                      money(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _printReceipt(Map<String, dynamic> receipt) async {
    await _run(() async {
      final order = store.orders
          .where((value) => value.id == receipt['orderId'])
          .firstOrNull;
      if (order == null) {
        throw StateError('No se encontró el pedido de esta nota.');
      }
      await printReceiptPdf(
        order: order,
        code: receipt['code'] as String,
        status: receipt['status'] as String? ?? 'VIGENTE',
      );
      if (receipt['id'] is int) {
        await store.recordReceiptPrint(receipt['id'] as int);
      }
    });
  }

  Widget _shift() {
    final collected = store.orders.fold<double>(
      0,
      (sum, order) => sum + order.paid,
    );
    final cash = store.orders.fold<double>(
      0,
      (sum, order) =>
          sum +
          order.payments
              .where((payment) => payment.method == 'Efectivo')
              .fold<double>(0, (sub, payment) => sub + payment.amount),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionTitle(
          title: 'Arqueo de caja',
          subtitle: 'Control de apertura, medios de pago y cierre',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.point_of_sale,
                      size: 30,
                      color: luxuryGold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        store.shiftOpen ? 'Turno abierto' : 'Turno cerrado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(
                      label: store.shiftOpen ? 'Abierto' : 'Cerrado',
                      color: store.shiftOpen ? luxuryGreen : luxuryRed,
                    ),
                  ],
                ),
                const Divider(height: 28),
                ResponsiveListTile(
                  title: const Text('Monto de apertura'),
                  trailing: Text(money(store.openingCash)),
                ),
                ResponsiveListTile(
                  title: const Text('Efectivo recaudado'),
                  trailing: Text(money(cash)),
                ),
                ResponsiveListTile(
                  title: const Text('Total recaudado'),
                  trailing: Text(
                    money(collected),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!store.shiftOpen)
                  ResponsiveListTile(
                    title: const Text('Monto de cierre registrado'),
                    trailing: Text(money(store.closedCash)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final controller = TextEditingController(
                        text: store.shiftOpen
                            ? (store.openingCash + cash).toStringAsFixed(2)
                            : '0.00',
                      );
                      final counted = await showDialog<double>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            store.shiftOpen ? 'Cerrar turno' : 'Abrir turno',
                          ),
                          content: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: store.shiftOpen ? 'Efectivo contado al cierre' : 'Fondo inicial (puede ser S/ 0.00)',
                              prefixText: 'S/ ',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                double.tryParse(controller.text),
                              ),
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      );
                      controller.dispose();
                      if (counted != null) {
                        await _run(
                          () => store.setShiftOpen(
                            !store.shiftOpen,
                            countedCash: counted,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      store.shiftOpen ? Icons.lock_outline : Icons.lock_open,
                    ),
                    label: Text(
                      store.shiftOpen ? 'Cerrar caja' : 'Abrir nuevo turno',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activity() {
    final recent = store.orders.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle(
          title: 'Actividad de caja',
          subtitle: 'Pedidos y pagos recientes',
        ),
        if (recent.isEmpty)
          const EmptyState(message: 'No hay actividad registrada.')
        else
          ...recent.map(
            (order) => Card(
              child: ResponsiveListTile(
                leading: Icon(
                  order.status == OrderStatus.paid
                      ? Icons.check_circle_outline
                      : Icons.receipt_long,
                  color: order.status == OrderStatus.paid
                      ? luxuryGreen
                      : luxuryBrown,
                ),
                title: Text('Pedido #${order.id} · Mesa ${order.tableNumber}'),
                subtitle: Text(
                  order.payments.isEmpty
                      ? 'Sin pagos registrados'
                      : order.payments
                            .map(
                              (payment) =>
                                  '${payment.method} ${money(payment.amount)}',
                            )
                            .join(' + '),
                ),
                trailing: Text(
                  money(order.paid),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _labels = [
    'Cuentas y cobros',
    'Notas de venta',
    'Arqueo de caja',
    'Actividad',
  ];
  static const _icons = [
    Icons.payments_outlined,
    Icons.receipt_long,
    Icons.point_of_sale,
    Icons.history,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final body = switch (page) {
        0 => _accounts(),
        1 => _receipts(),
        2 => _shift(),
        _ => _activity(),
      };
      return Scaffold(
        body: Row(
          children: [
            if (!narrow && widget.navigationController == null) ...[
              NavigationRail(
                scrollable: true,
                selectedIndex: page,
                onDestinationSelected: (value) => setState(() => page = value),
                extended: constraints.maxWidth > 1050,
                labelType: constraints.maxWidth > 1050
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
