import 'package:luxury_app/widgets/luxury_feedback.dart';
import 'package:luxury_app/widgets/luxury_banner.dart';
import 'package:flutter/material.dart';
import 'package:luxury_app/widgets/luxury_progress.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/core/utils/formatters.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/services/receipt_pdf.dart';
import 'package:luxury_app/widgets/widgets.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({
    super.key,
    required this.store,
    this.navigationController,
  });
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

  bool _running = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_running) return;
    _running = true;
    try {
      await showBlockingProgress<void>(
        context,
        action: action,
        label: 'Procesando…',
      );
    } catch (error) {
      if (mounted) {
        LuxuryFeedback.error(context, LuxuryFeedback.message(error));
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _collect(AccountGroup group) async {
    if (!store.shiftOpen) {
      setState(() => page = 2);
      LuxuryFeedback.error(
        context,
        'Administración debe abrir el turno de caja asignado a este cajero.',
      );
      return;
    }
    if (!group.kitchenFinished) {
      LuxuryFeedback.error(
        context,
        'Cocina aún no termina esta cuenta. Podrás cobrar cuando todos los platillos estén listos.',
      );
      return;
    }
    final splits = await showDialog<List<PaymentSplit>>(
      context: context,
      builder: (context) => _SplitPaymentDialog(group: group),
    );
    if (splits == null) return;
    await _run(() async {
      await store.payAccount(accountOrders: group.orders, splits: splits);
      final change = splits.fold<double>(0, (sum, split) {
        if (split.method != 'Efectivo') return sum;
        final extra = (split.cashReceived ?? split.amount) - split.amount;
        return sum + (extra > 0 ? extra : 0);
      });
      if (mounted) setState(() {});
      if (mounted) {
        await LuxuryFeedback.success(
          context,
          title: 'Cobro registrado',
          message: change > 0
              ? 'Se cobró ${group.label} por ${money(group.balance)}. Entrega el vuelto de ${money(change)}.'
              : 'Se cobró ${group.label} por ${money(group.balance)} correctamente.',
        );
      }
    });
  }

  Widget _accounts() {
    final accounts = store.openAccounts;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const LuxuryBanner(
          eyebrow: 'Cobros y servicio',
          title: 'Caja y precuentas',
          description: 'Consulta cada consumo antes de registrar un pago.',
          icon: Icons.receipt_long_rounded,
        ),
        const SectionTitle(
          title: 'Cuentas y cobros',
          subtitle:
              'Una cuenta por mesa: se actualiza con cada pedido que agregan al salón',
        ),
        if (!store.shiftOpen)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: luxuryRed),
              title: Text('Tu turno de hoy no está abierto'),
              subtitle: Text(
                'Administración debe abrir tu turno para que puedas registrar cobros.',
              ),
            ),
          ),
        if (accounts.isEmpty)
          const EmptyState(
            message: 'No hay cuentas pendientes de pago.',
            icon: Icons.task_alt,
          )
        else
          ...accounts.map(_accountCard),
      ],
    );
  }

  Widget _accountCard(AccountGroup group) {
    final ready = group.kitchenFinished;
    return Card(
      child: ExpansionTile(
        key: ValueKey(group.key),
        leading: CircleAvatar(
          backgroundColor: luxuryGold.withValues(alpha: .14),
          child: group.isTable
              ? Text('${group.first.tableNumber}')
              : const Icon(Icons.delivery_dining, size: 20),
        ),
        title: Text(
          group.orders.length > 1
              ? '${group.label} · ${group.orders.length} pedidos'
              : '${group.label} · Pedido #${group.first.id}',
        ),
        subtitle: Text(
          '${group.lines.length} productos · Total ${money(group.total)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Saldo', style: TextStyle(fontSize: 11)),
            Text(
              money(group.balance),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: luxuryRed,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    label: ready ? 'Cocina lista' : 'Cocina preparando',
                    color: ready ? luxuryGreen : luxuryGold,
                  ),
                  if (group.billRequested)
                    StatusBadge(label: 'Cuenta solicitada', color: luxuryBrown),
                ],
              ),
            ),
          ),
          for (final order in group.orders) ...[
            if (group.orders.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    order.parentOrderId == null
                        ? 'Pedido #${order.id}'
                        : 'Pedido #${order.id} (adicional)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ...order.lines.map(
              (line) => ResponsiveListTile(
                dense: true,
                title: Text('${line.quantity} × ${line.name}'),
                subtitle: line.note.isEmpty ? null : Text(line.note),
                trailing: Text(money(line.subtotal)),
              ),
            ),
          ],
          ...group.payments.map(
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
              onPressed: () => _run(() => printPreBillPdf(group.combined)),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Ver / imprimir precuenta (sin cobrar)'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ready ? () => _collect(group) : null,
                icon: Icon(ready ? Icons.point_of_sale : Icons.hourglass_top),
                label: Text(
                  !ready
                      ? 'Esperando a Cocina…'
                      : group.paid > 0
                      ? 'Cobrar saldo · ${money(group.balance)}'
                      : 'Cobrar cuenta · ${money(group.balance)}',
                ),
              ),
            ),
          ),
        ],
      ),
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
                      '${order.placeLabel} · ${order.payments.map((payment) => payment.method).toSet().join(', ')}',
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
    final today = DateTime.now();
    bool isToday(DateTime date) {
      final local = date.toLocal();
      return local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
    }

    final paymentsToday = store.orders
        .expand((order) => order.payments)
        .where((payment) => isToday(payment.createdAt));
    final collected = paymentsToday.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final cash = paymentsToday
        .where((payment) => payment.method == 'Efectivo')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionTitle(
          title: 'Arqueo de caja',
          subtitle: 'Ingresos de hoy; conserva el historial de otros días',
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
                    onPressed:
                        null, // Solo administración debe abrir y cerrar caja.
                    icon: Icon(
                      store.shiftOpen ? Icons.lock_outline : Icons.lock_open,
                    ),
                    label: Text('Apertura y cierre: administrador'),
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
                title: Text('Pedido #${order.id} · ${order.placeLabel}'),
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

class _SplitRow {
  _SplitRow(this.method, double initial)
    : amount = TextEditingController(text: initial.toStringAsFixed(2)),
      received = TextEditingController(text: initial.toStringAsFixed(2)),
      reference = TextEditingController();

  String method;
  final TextEditingController amount;
  final TextEditingController received;
  final TextEditingController reference;
  bool receivedTouched = false;

  void dispose() {
    amount.dispose();
    received.dispose();
    reference.dispose();
  }
}

/// Cobro de una cuenta completa. El total es fijo (no se edita) y puede
/// repartirse entre varios métodos de pago que deben sumar exactamente.
class _SplitPaymentDialog extends StatefulWidget {
  const _SplitPaymentDialog({required this.group});
  final AccountGroup group;

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  static const _methods = ['Efectivo', 'Yape', 'Plin', 'Tarjeta'];
  late final List<_SplitRow> rows;
  final List<_SplitRow> _removed = [];

  double get balance => widget.group.balance;

  @override
  void initState() {
    super.initState();
    rows = [_SplitRow('Efectivo', balance)];
  }

  @override
  void dispose() {
    for (final row in [...rows, ..._removed]) {
      row.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  double get assigned => rows.fold(0, (sum, row) => sum + _value(row.amount));
  double get remaining => balance - assigned;

  double get change => rows
      .where((row) => row.method == 'Efectivo')
      .fold<double>(0, (sum, row) {
        final extra = _value(row.received) - _value(row.amount);
        return sum + (extra > 0 ? extra : 0);
      });

  void _addRow() {
    setState(() {
      final method = rows.any((row) => row.method == 'Efectivo')
          ? 'Yape'
          : 'Efectivo';
      rows.add(_SplitRow(method, 0));
    });
  }

  void _fill(_SplitRow row) {
    final value = _value(row.amount) + remaining;
    if (value <= 0) return;
    setState(() {
      row.amount.text = value.toStringAsFixed(2);
      if (!row.receivedTouched) row.received.text = row.amount.text;
    });
  }

  String? _error() {
    if (remaining.abs() > .009) {
      return remaining > 0
          ? 'Falta asignar ${money(remaining)} para completar la cuenta.'
          : 'Los pagos superan la cuenta por ${money(-remaining)}.';
    }
    for (final row in rows) {
      final amount = _value(row.amount);
      if (amount <= 0) return 'Cada método debe tener un monto mayor a cero.';
      if (row.method == 'Efectivo') {
        if (_value(row.received) + .001 < amount) {
          return 'El efectivo recibido debe cubrir el monto en efectivo.';
        }
      } else if (row.reference.text.trim().isEmpty) {
        return 'Registra el número de operación de ${row.method}.';
      }
    }
    return null;
  }

  List<PaymentSplit> _splits() => [
    for (final row in rows)
      PaymentSplit(
        method: row.method,
        amount: _value(row.amount),
        reference: row.reference.text.trim(),
        cashReceived: row.method == 'Efectivo' ? _value(row.received) : null,
      ),
  ];

  Widget _rowCard(int index) {
    final row = rows[index];
    final locked = rows.length == 1;
    return Card(
      key: ObjectKey(row),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('split-method-$index'),
                    initialValue: row.method,
                    decoration: InputDecoration(
                      labelText: locked
                          ? 'Método de pago'
                          : 'Método ${index + 1}',
                    ),
                    items: [
                      for (final method in _methods)
                        DropdownMenuItem(value: method, child: Text(method)),
                    ],
                    onChanged: (value) =>
                        setState(() => row.method = value ?? row.method),
                  ),
                ),
                if (!locked)
                  IconButton(
                    tooltip: 'Quitar método',
                    onPressed: () => setState(() {
                      _removed.add(rows.removeAt(index));
                    }),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: ValueKey('split-amount-$index'),
              controller: row.amount,
              enabled: !locked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (!row.receivedTouched) row.received.text = row.amount.text;
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: locked ? 'Monto (bloqueado)' : 'Monto',
                prefixText: 'S/ ',
                suffixIcon: locked ? const Icon(Icons.lock_outline) : null,
              ),
            ),
            if (!locked)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _fill(row),
                  child: const Text('Completar con lo que falta'),
                ),
              ),
            const SizedBox(height: 6),
            if (row.method == 'Efectivo')
              TextField(
                key: ValueKey('split-received-$index'),
                controller: row.received,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  row.receivedTouched = true;
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Efectivo recibido',
                  prefixText: 'S/ ',
                ),
              )
            else
              TextField(
                key: ValueKey('split-reference-$index'),
                controller: row.reference,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'N.º de operación · ${row.method}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _error();
    final group = widget.group;
    final diff = remaining;
    return AlertDialog(
      title: Text('Cobrar · ${group.label}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Total a cobrar (fijo)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                child: Text(
                  money(balance),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (group.paid > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Total de la cuenta ${money(group.total)} · ya pagado ${money(group.paid)}',
                  ),
                ),
              const SizedBox(height: 12),
              for (var i = 0; i < rows.length; i++) _rowCard(i),
              TextButton.icon(
                onPressed: rows.length >= 4 ? null : _addRow,
                icon: const Icon(Icons.call_split),
                label: const Text('Dividir con otro método'),
              ),
              Text(
                'Asignado ${money(assigned)} · ${diff.abs() <= .009
                    ? 'cuenta completa'
                    : diff > 0
                    ? 'falta ${money(diff)}'
                    : 'excede ${money(-diff)}'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (change > 0) Text('Vuelto para entregar: ${money(change)}'),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: error == null
              ? () => Navigator.pop(context, _splits())
              : null,
          child: const Text('Registrar cobro'),
        ),
      ],
    );
  }
}
