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

  test(
    'La cuenta acepta cobros sucesivos y conserva su total original',
    () async {
      final store = RestaurantStore();
      addTearDown(store.dispose);
      await store.loginDemo(StaffRole.administrator);
      await store.setShiftOpen(true, countedCash: 0);

      final table = store.tables.firstWhere((value) => value.id == 1);
      await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
      final order = store.orders.first;
      final total = order.total;

      await store.recordPayment(
        order: order,
        method: 'Efectivo',
        amount: 8,
        cashReceived: 10,
        earlyPaymentConfirmed: true,
      );
      await store.recordPayment(
        order: store.orders.first,
        method: 'Yape',
        amount: 10,
        reference: 'OP-123',
        earlyPaymentConfirmed: true,
      );

      expect(store.orders.first.total, total);
      expect(store.orders.first.balance, 0);
      expect(store.orders.first.payments.map((payment) => payment.method), [
        'Efectivo',
        'Yape',
      ]);
    },
  );

  test(
    'Un pedido abierto puede enviar agregados como comandas nuevas',
    () async {
      final store = RestaurantStore();
      addTearDown(store.dispose);
      await store.loginDemo(StaffRole.waiter);
      store.orders.clear();
      final table = store.tables.firstWhere((value) => value.id == 1);

      await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
      final parent = store.orders.first;
      await store.createOrder(
        table: table,
        diners: 1,
        parentOrderId: parent.id,
        lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
      );

      expect(store.orders.first.parentOrderId, parent.id);
      expect(store.orders.first.lines.single.name, 'Chicha morada jarra');
    },
  );

  test(
    'Una mesa pagada admite un pedido independiente antes del retiro',
    () async {
      final store = RestaurantStore();
      addTearDown(store.dispose);
      await store.loginDemo(StaffRole.administrator);
      await store.setShiftOpen(true, countedCash: 0);
      final table = store.tables.firstWhere((value) => value.id == 1);

      await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);
      final paidOrder = store.orders.first;
      await store.recordPayment(
        order: paidOrder,
        method: 'Efectivo',
        amount: paidOrder.total,
        cashReceived: paidOrder.total,
        earlyPaymentConfirmed: true,
      );
      await store.createOrder(
        table: table,
        diners: 1,
        lines: [sampleLine(menuItemId: 10, name: 'Chicha morada jarra')],
      );

      expect(store.orders.first.parentOrderId, isNull);
      expect(store.orders.first.id, isNot(paidOrder.id));
      expect(
        store.orders.singleWhere((value) => value.id == paidOrder.id).status,
        OrderStatus.paid,
      );
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

  testWidgets(
    'Caja cobra sucesivamente y calcula vuelto sin editar la cuenta',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = RestaurantStore();
      addTearDown(store.dispose);
      await store.loginDemo(StaffRole.administrator);
      await store.setShiftOpen(true, countedCash: 0);
      store.orders.clear();
      await store.createOrder(
        table: store.tables.firstWhere((value) => value.id == 1),
        diners: 1,
        lines: [sampleLine(unitPrice: 100)],
      );
      final order = store.orders.first;
      await store.advanceOrder(order);
      await store.advanceOrder(store.orders.first);
      await store.advanceOrder(store.orders.first);

      await tester.pumpWidget(MaterialApp(home: CashierScreen(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      final firstCharge = find.widgetWithText(
        FilledButton,
        'Cobrar cuenta · S/ 100.00',
      );
      await tester.ensureVisible(firstCharge);
      await tester.tap(firstCharge);
      await tester.pumpAndSettle();

      expect(
        find.text('Total original de la cuenta: S/ 100.00'),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tarjeta').last);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '40');
      await tester.enterText(find.byType(TextField).last, 'CARD-40');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Registrar pago'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Registrar pago'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.orders.first.payments, hasLength(1));
      expect(store.orders.first.payments.first.amount, 40);
      expect(store.orders.first.balance, 60);
      expect(find.text('Pago registrado'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      final nextCharge = find.widgetWithText(
        FilledButton,
        'Registrar siguiente abono · S/ 60.00',
      );
      await tester.ensureVisible(nextCharge);
      await tester.tap(nextCharge);
      await tester.pumpAndSettle();
      expect(
        find.text('Total original de la cuenta: S/ 100.00'),
        findsOneWidget,
      );
      expect(
        find.text('Pagado: S/ 40.00 · Saldo pendiente: S/ 60.00'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).last, '100');
      await tester.pumpAndSettle();
      expect(find.text('Vuelto para entregar: S/ 40.00'), findsOneWidget);
      await tester.tap(find.text('Registrar pago'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.orders.first.balance, 0);
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('Editar pedido abre directamente el pedido y su mesa', (
    tester,
  ) async {
    final store = RestaurantStore();
    addTearDown(store.dispose);
    await store.loginDemo(StaffRole.waiter);
    store.orders.clear();
    final table = store.tables.firstWhere((value) => value.id == 1);
    await store.createOrder(table: table, diners: 1, lines: [sampleLine()]);

    await tester.pumpWidget(MaterialApp(home: WaiterScreen(store: store)));
    await tester.pumpAndSettle();
    tester
        .widget<NavigationRail>(find.byType(NavigationRail))
        .onDestinationSelected!(2);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Editar pedido · Mesa 1'), findsOneWidget);
  });
}
