# Corrección de Delivery — 9 de noviembre de 2026

## Qué se corrigió en Flutter
- La opción Delivery solo está disponible para Caja, Administrador y Gerente.
- Mesero conserva solo Para llevar; no puede marcar entregado un pedido Delivery.
- Los errores de tabla inexistente, permisos o validaciones se muestran en español.
- Si falla la sincronización, el pedido queda como borrador local: **no llega a Cocina ni a Caja**.

## Importante: instalación en Supabase
1. En un proyecto de pruebas, abrir **Supabase > SQL Editor**.
2. Si nunca se instaló el módulo: ejecutar primero `supabase/migrations/20261108_pedidos_externos.sql`. Este archivo crea la tabla, las políticas y la función de cambio de estado.
3. Si la tabla ya existía: ejecutar `supabase/migrations/20261109_permisos_delivery.sql`, que restringe Delivery a Caja, Gerente y Administrador.
4. Verificar con cuentas de Mesero y Caja. No ejecutar migraciones a ciegas sobre producción; hacer respaldo y revisar el esquema real.

## Pruebas sugeridas
- Caja: crear pedido Delivery con cliente, teléfono, dirección y al menos un producto.
- Mesero: comprobar que no aparezca Delivery (solo Para llevar).
- Al guardar, comprobar que el pedido aparezca en «Pedidos registrados» y desaparezca de «Pendientes locales».
- Si figura «SIN SINCRONIZAR», falta aplicar SQL, hay permisos insuficientes o un problema de red.

## Limitación pendiente
Este módulo guarda pedidos externos en una tabla separada. **Aún no integra automáticamente** sus ventas con la caja, inventario ni el flujo tradicional de comandas de Cocina. No se debe asumir que ya forma parte de los reportes financieros del restaurante.

Este parche se revisó por inspección de código. No se pudo ejecutar Flutter ni conectar con tu Supabase desde este entorno.
