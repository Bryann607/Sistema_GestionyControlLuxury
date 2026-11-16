import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/views/cashier/cashier_screen.dart';
import 'package:luxury_app/views/waiter/waiter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  OrderLine sampleLine({
    int menuItemId = 1,
    String name = 'Wantán frito',
    double unitPrice = 18,
  }) => OrderLine(
    menuItemId: menuItemId,
    name: name,
    quantity: 1,
    unitPrice: unitPrice,
  );

  /// Cocina toma el pedido y lo deja listo (pendiente → preparando → listo).
  Future<void> cook(RestaurantStore store, int orderId) async {
    for (var i = 0; i < 2; i++) {
      await store.advanceOrder(
        store.orders.firstWhere((order) => order.id == orderId),
      );
    }
  }

  Future<RestaurantStore> cashierStore() async {
    final store = RestaurantStore();
    await store.loginDemo(StaffRole.administrator);
    await store.setShiftOpen(true, countedCash: 0);
    store.orders.clear();
    return store;
  }

  test('No se cobra mientras Cocina no termina el pedido', () async {
    final store = await cashierStore();
    addTearDown(store.dispose);
    final table = store.tables.firstWhere((value) => value.id == 1);
    await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
    final order = store.orders.first;

    await expectLater(
      store.recordPayment(
        order: order,
        method: 'Efectivo',
        amount: order.total,
        cashReceived: order.total,
      ),
      throwsStateError,
    );
    expect(store.orders.first.payments, isEmpty);

    await cook(store, order.id);
    await store.recordPayment(
      order: store.orders.first,
      method: 'Efectivo',
      amount: order.total,
      cashReceived: order.total,
    );
    expect(store.orders.first.status, OrderStatus.paid);
  });

  test('Confirmar entrega exige que Cocina haya terminado', () async {
    final store = await cashierStore();
    addTearDown(store.dispose);
    final table = store.tables.firstWhere((value) => value.id == 1);
    await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
    final id = store.orders.first.id;

    await expectLater(
      store.confirmDelivery(store.orders.first),
      throwsStateError,
    );
    // Intentar entregar no debe haber adelantado la comanda de Cocina.
    expect(kitchenStage(store.orders.first), OrderStatus.pending);

    await cook(store, id);
    await store.confirmDelivery(store.orders.first);
    expect(kitchenStage(store.orders.first), OrderStatus.delivered);
  });

  test('Un pedido nuevo en una mesa abierta se suma a su cuenta', () async {
    final store = await cashierStore();
    addTearDown(store.dispose);
    final table = store.tables.firstWhere((value) => value.id == 1);

    await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
    final parent = store.orders.first;
    await store.createOrder(
      table: table,
      diners: 1,
      lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
    );

    expect(store.orders.first.parentOrderId, parent.id);
    final accounts = store.openAccounts;
    expect(accounts, hasLength(1));
    expect(accounts.single.orders, hasLength(2));
  });

  test(
    'Pagar una cuenta repartida en efectivo y Yape cubre toda la mesa',
    () async {
      final store = await cashierStore();
      addTearDown(store.dispose);
      final table = store.tables.firstWhere((value) => value.id == 1);
      await store.createOrder(table: table, diners: 2, lines: [sampleLine()]);
      final first = store.orders.first;
      await store.createOrder(
        table: table,
        diners: 2,
        lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
      );
      final second = store.orders.first;
      await cook(store, first.id);
      await cook(store, second.id);

      final account = store.openAccounts.single;
      final total = account.balance;
      expect(total, 36);

      await expectLater(
        store.payAccount(
          accountOrders: account.orders,
          splits: const [
            PaymentSplit(method: 'Efectivo', amount: 20, cashReceived: 20),
          ],
        ),
        throwsStateError,
        reason: 'Los pagos deben sumar exactamente la cuenta',
      );
      expect(store.orders.expand((order) => order.payments), isEmpty);

      await store.payAccount(
        accountOrders: account.orders,
        splits: const [
          PaymentSplit(method: 'Efectivo', amount: 20, cashReceived: 50),
          PaymentSplit(method: 'Yape', amount: 16, reference: 'OP-77'),
        ],
      );

      expect(
        store.orders.every((order) => order.status == OrderStatus.paid),
        isTrue,
      );
      expect(store.openAccounts, isEmpty);
      final methods = store.orders
          .expand((order) => order.payments)
          .map((payment) => payment.method)
          .toSet();
      expect(methods, {'Efectivo', 'Yape'});
      final collected = store.orders
          .expand((order) => order.payments)
          .fold<double>(0, (sum, payment) => sum + payment.amount);
      expect(collected, closeTo(36, 0.001));
    },
  );

  test(
    'Con la cuenta pedida la mesa no admite pedidos; tras pagar abre otra',
    () async {
      final store = await cashierStore();
      addTearDown(store.dispose);
      final table = store.tables.firstWhere((value) => value.id == 1);
      await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
      final first = store.orders.first;

      await store.requestBill(store.liveTableOrders(table.id).toList());
      expect(store.tableBillingStarted(table), isTrue);
      await expectLater(
        store.createOrder(table: table, diners: 1, lines: [sampleLine()]),
        throwsStateError,
      );

      await cook(store, first.id);
      await store.payAccount(
        accountOrders: store.openAccounts.single.orders,
        splits: [
          PaymentSplit(
            method: 'Efectivo',
            amount: first.total,
            cashReceived: first.total,
          ),
        ],
      );
      expect(store.tableBillingStarted(table), isFalse);

      await store.createOrder(
        table: table,
        diners: 1,
        lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
      );
      expect(store.orders.first.parentOrderId, isNull);
      expect(store.orders.first.id, isNot(first.id));
    },
  );

  testWidgets('Pedir cuenta no permite confirmar entrega antes de cocina', (
    tester,
  ) async {
    final store = RestaurantStore();
    addTearDown(store.dispose);
    await store.loginDemo(StaffRole.waiter);
    store.orders.clear();
    await store.createOrder(
      table: store.tables.firstWhere((value) => value.id == 1),
      diners: 1,
      lines: [sampleLine()],
    );

    await tester.pumpWidget(MaterialApp(home: WaiterScreen(store: store)));
    await tester.pumpAndSettle();
    tester
        .widget<NavigationRail>(find.byType(NavigationRail))
        .onDestinationSelected!(2);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega'), findsNothing);
    expect(find.text('Solicitar cuenta'), findsOneWidget);
  });

  testWidgets('El menú de la mesa abre directamente la edición del pedido', (
    tester,
  ) async {
    final store = RestaurantStore();
    addTearDown(store.dispose);
    await store.loginDemo(StaffRole.waiter);
    store.orders.clear();
    final table = store.tables.firstWhere((value) => value.id == 1);
    await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
    final id = store.orders.first.id;

    await tester.pumpWidget(MaterialApp(home: WaiterScreen(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mesa 1'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar productos a cocina'), findsOneWidget);
    final editTile = find.text('Editar pedido #$id');
    await tester.ensureVisible(editTile);
    await tester.tap(editTile);
    await tester.pumpAndSettle();

    expect(find.text('Editar pedido · Mesa 1'), findsOneWidget);
  });

  testWidgets('Nuevo pedido vuelve a pedir mesa y no conserva la anterior', (
    tester,
  ) async {
    final store = RestaurantStore();
    addTearDown(store.dispose);
    await store.loginDemo(StaffRole.waiter);
    await tester.pumpWidget(MaterialApp(home: WaiterScreen(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mesa 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo pedido').last);
    await tester.pumpAndSettle();
    expect(find.text('Nueva comanda · Mesa 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver a mesas'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Nuevo pedido'));
    await tester.pumpAndSettle();
    expect(
      find.text('Selecciona la mesa antes de registrar productos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Mesa 3'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva comanda · Mesa 3'), findsOneWidget);
  });

  testWidgets(
    'Caja agrupa la mesa y bloquea el cobro hasta que Cocina termine',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await cashierStore();
      addTearDown(store.dispose);
      final table = store.tables.firstWhere((value) => value.id == 1);
      await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
      await store.createOrder(
        table: table,
        diners: 1,
        lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
      );

      await tester.pumpWidget(MaterialApp(home: CashierScreen(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('Mesa 1 · 2 pedidos'), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      final waiting = find.widgetWithText(FilledButton, 'Esperando a Cocina…');
      await tester.ensureVisible(waiting);
      expect(tester.widget<FilledButton>(waiting).onPressed, isNull);
    },
  );

  testWidgets(
    'Caja divide el cobro con total fijo y cobra cuando suma exacto',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await cashierStore();
      addTearDown(store.dispose);
      await store.createOrder(
        table: store.tables.firstWhere((value) => value.id == 1),
        diners: 1,
        lines: [sampleLine(unitPrice: 100)],
      );
      await cook(store, store.orders.first.id);

      await tester.pumpWidget(MaterialApp(home: CashierScreen(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      final charge = find.widgetWithText(
        FilledButton,
        'Cobrar cuenta · S/ 100.00',
      );
      await tester.ensureVisible(charge);
      await tester.tap(charge);
      await tester.pumpAndSettle();

      // Con un solo método el monto está bloqueado.
      expect(find.text('Total a cobrar (fijo)'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('split-amount-0')))
            .enabled,
        isFalse,
      );

      await tester.tap(find.text('Dividir con otro método'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('split-amount-0')),
        '40',
      );
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Registrar cobro');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.text('Completar con lo que falta').last);
      await tester.pumpAndSettle();
      final reference = find.byKey(const ValueKey('split-reference-1'));
      await tester.ensureVisible(reference);
      await tester.enterText(reference, 'OP-9');
      await tester.pumpAndSettle();
      await tester.ensureVisible(confirm);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final payments = store.orders.first.payments;
      expect(payments.map((payment) => payment.method), ['Efectivo', 'Yape']);
      expect(payments.map((payment) => payment.amount), [40, 60]);
      expect(store.orders.first.balance, 0);
      expect(find.text('Cobro registrado'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
