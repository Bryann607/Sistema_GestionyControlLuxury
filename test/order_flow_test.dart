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

  OrderLine sampleLine({int menuItemId = 1, String name = 'Wantán frito'}) =>
      OrderLine(menuItemId: menuItemId, name: name, quantity: 1, unitPrice: 18);

  test(
    'La cuenta acepta pagos divididos y conserva el total del pedido',
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

  testWidgets('Caja permite dividir el pago sin editar el total', (
    tester,
  ) async {
    final store = RestaurantStore();
    addTearDown(store.dispose);
    await store.loginDemo(StaffRole.administrator);
    await store.setShiftOpen(true, countedCash: 0);
    store.orders.clear();
    await store.createOrder(
      table: store.tables.firstWhere((value) => value.id == 1),
      diners: 1,
      lines: [sampleLine()],
    );
    final order = store.orders.first;
    await store.advanceOrder(order);
    await store.advanceOrder(store.orders.first);
    await store.advanceOrder(store.orders.first);

    await tester.pumpWidget(MaterialApp(home: CashierScreen(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Cobrar cuenta · S/ 18.00'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total de la cuenta: S/ 18.00'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.text('Agregar otra forma de pago'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(tester.takeException(), isNull);
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
