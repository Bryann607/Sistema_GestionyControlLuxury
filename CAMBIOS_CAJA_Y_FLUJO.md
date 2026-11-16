# Cambios: caja, cocina y pedidos de mesa

## Antes de probar (Supabase)
1. Aplicar `supabase/migrations/20261115005100_Fix_cashier_shifts_and_new_table_orders.sql`.
   Sin ella el login de **cajero** falla (usa el RPC `obtener_turno_caja_actual`).
2. Administración debe **abrir el turno de cada cajero** (Dashboard > Abrir caja > elegir cajero).
   El servidor solo deja cobrar con un turno abierto **hoy (hora de Lima)** a nombre del propio cajero.

## Por qué Caja no cobraba
El cajero no puede leer `turnos_caja` (RLS solo para Administración), así que la app veía la caja
siempre cerrada. Ahora el turno se consulta con el RPC `obtener_turno_caja_actual` y Administración
abre/cierra el turno **por cajero** con `administrar_turno_caja`.

## Flujo de Cocina → entrega → cobro
- **Confirmar entrega**: solo aparece (y solo funciona) cuando Cocina terminó todos los platillos.
  Antes llamaba a `advanceOrder`, que podía adelantar la comanda de Cocina. Ahora usa `confirmDelivery`.
- **Solicitar cuenta**: disponible en cualquier momento; pide la cuenta de **toda la mesa** (`requestBill`).
- **Cobro**: bloqueado hasta que Cocina termine. Se eliminó el "cobro anticipado" (UI y store).
  La caja muestra "Esperando a Cocina…" y el botón de cobrar deshabilitado.

## Caja
- Una **cuenta por mesa**: suma el pedido principal y todos los consumos adicionales y se actualiza
  sola cuando el mesero agrega algo. Delivery y para llevar siguen siendo una cuenta por pedido.
- **Pago dividido** en un solo diálogo (Efectivo, Yape, Plin, Tarjeta):
  - El total a cobrar es fijo (no editable). Con un solo método, el monto también queda bloqueado.
  - Con varios métodos, deben sumar **exactamente** el total; muestra lo que falta y el vuelto.
  - Los pagos se reparten entre los pedidos de la mesa (`registrar_pago` por pedido).

## Mesero
- **Editar pedido** aparece directo en el menú de la mesa (mientras Cocina no haya iniciado).
- **Agregar productos a cocina** (p. ej. agua): crea una comanda nueva ligada a la cuenta abierta;
  sí llega a Cocina como comanda aparte. Todo pedido nuevo en una mesa con cuenta abierta se suma a ella.
- Con la cuenta pedida o con abonos, la mesa no admite más pedidos hasta completar el pago.
- **Tras pagar la cuenta completa**, el siguiente pedido abre una cuenta nueva.
- "Nuevo pedido" ya no reutiliza la última mesa: siempre pide elegirla.
- Los pedidos de mesa ahora se crean con `crear_pedido_sincronizado` (que deriva a
  `crear_consumo_mesa` para los consumos adicionales antes del cobro).

## Tests
`test/order_flow_test.dart` fue reescrito: cobro y entrega bloqueados, cuenta por mesa, pago mixto,
mesa en cobro, edición directa, "Nuevo pedido" y el diálogo de pago dividido.

Ejecutar: `flutter pub get && flutter analyze && flutter test`

> Nota: estos cambios se revisaron sin compilador. Si `flutter analyze` o algún test marca algo, es lo
> primero que hay que corregir.
