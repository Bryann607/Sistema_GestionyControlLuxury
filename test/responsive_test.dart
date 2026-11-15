import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/views/admin/admin_screen.dart';
import 'package:luxury_app/views/cashier/cashier_screen.dart';
import 'package:luxury_app/views/kitchen/kitchen_screen.dart';
import 'package:luxury_app/views/waiter/waiter_screen.dart';
import 'package:luxury_app/widgets/widgets.dart';

void main() {
  for (final size in [
    (320.0, 1.0),
    (390.0, 1.0),
    (600.0, 1.0),
    (768.0, 1.0),
    (844.0, 1.0),
    (1280.0, 1.0),
    (390.0, 1.5),
  ]) {
    testWidgets('Administración: ancho ${size.$1}, texto ${size.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(size.$1, size.$1 == 844 ? 390 : 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = RestaurantStore();
      store.menu.insert(
        0,
        const MenuItem(
          id: 9999,
          name: 'Arroz chaufa especial',
          category: 'Chifas',
          price: 15,
          description: 'Con verduras y pollo, preparado al momento',
        ),
      );
      store.inventory.insert(
        0,
        const InventoryItem(
          id: 9999,
          name: 'Ajo para cocina',
          description: 'Insumo fresco para la preparación del día',
          unit: 'UNIDAD',
          quantity: 1,
          minimum: 1,
        ),
      );
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(size.$2)),
            child: child!,
          ),
          home: Scaffold(body: AdminScreen(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Resumen');
      for (var page = 1; page < 8; page++) {
        if (size.$1 < 760) {
          await tester.tap(find.byType(DropdownButtonFormField<int>));
          await tester.pumpAndSettle();
          final label = [
            'Resumen',
            'Menú y catálogo',
            'Inventario',
            'Usuarios y roles',
            'Mesas',
            'Reportes',
            'Incidencias',
            'Auditoría',
          ][page];
          await tester.tap(find.text(label).last);
        } else {
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .onDestinationSelected!(page);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Sección $page');
        if (page == 1 || page == 2 || page == 4) {
          final name = page == 1
              ? 'Arroz chaufa especial'
              : page == 2
              ? 'Ajo para cocina'
              : 'Mesa ${store.tables.first.number}';
          final record = find
              .descendant(
                of: find.byType(ResponsiveListTile),
                matching: find.text(name),
              )
              .first;
          expect(
            tester.renderObject<RenderBox>(record).constraints.maxWidth,
            greaterThan(150),
          );
          if (page == 1 && size.$1 < 760) {
            expect(
              tester.getTopLeft(find.text('Nuevo plato')).dy,
              greaterThan(
                tester.getBottomLeft(find.text('Menú y catálogo').last).dy,
              ),
            );
          }
        }
        if (page == 2) {
          final segments = tester.widget<SegmentedButton<int>>(
            find.byType(SegmentedButton<int>),
          );
          for (final tab in [1, 2, 0]) {
            segments.onSelectionChanged!({tab});
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Inventario $tab');
          }
        }
      }
    });
  }

  for (final viewport in [
    Size(320, 900),
    Size(390, 900),
    Size(768, 900),
    Size(1280, 900),
    Size(844, 390),
    Size(640, 360),
  ]) {
    final width = viewport.width;
    testWidgets('Mesero, cocina y caja: $viewport', (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = RestaurantStore();
      addTearDown(store.dispose);
      for (final screen in [
        (WaiterScreen(store: store), 5),
        (KitchenScreen(store: store), 3),
        (CashierScreen(store: store), 5),
      ]) {
        await tester.pumpWidget(MaterialApp(home: screen.$1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (screen.$1 is WaiterScreen) {
          await tester.tap(find.widgetWithText(FilledButton, 'Nuevo pedido'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Nueva comanda');
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('add-menu-item-${store.menu.first.id}')),
            100,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('order-form-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(ValueKey('add-menu-item-${store.menu.first.id}')),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Comanda con productos',
          );
          expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
        }
        for (var page = 1; page < screen.$2; page++) {
          if (width < 760) {
            final nav = tester.widget<NavigationBar>(
              find.byType(NavigationBar),
            );
            if (page >= nav.destinations.length) break;
            nav.onDestinationSelected!(page);
          } else {
            final nav = tester.widget<NavigationRail>(
              find.byType(NavigationRail),
            );
            if (page >= nav.destinations.length) break;
            nav.onDestinationSelected!(page);
          }
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.$1.runtimeType}, sección $page',
          );
        }
      }
    });
  }
}
