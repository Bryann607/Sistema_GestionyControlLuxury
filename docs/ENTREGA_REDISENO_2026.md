# Luxury – actualización de interfaz, operaciones y acceso

Esta entrega se realizó **a partir de `Sistema_GestionyControlLuxury(2).zip`**. Las referencias visuales se utilizaron como inspiración, no como imágenes insertadas directamente en las pantallas. Se conservan los colores corporativos y el logo.

## Cambios en código

- `lib/core/theme/app_theme.dart`: nueva apariencia consistente para tarjetas, controles, navegación, botones y superficies.
- `lib/views/auth/login_screen.dart`: nuevos textos, distribución e imagen de marca; no presenta recuperación autónoma.
- `lib/views/work_screen.dart`: menú de cuenta con salida, indicador de función del rol y entrada a pedidos externos. Responsive: lateral en escritorio y drawer en móvil.
- `lib/widgets/luxury_banner.dart`: cabeceras para pantallas funcionales.
- `lib/views/admin/admin_screen.dart`, `lib/views/waiter/waiter_screen.dart`, `lib/views/kitchen/kitchen_screen.dart`, `lib/views/cashier/cashier_screen.dart`: encabezados temáticos en los paneles principales.
- `lib/controllers/restaurant_store.dart`: no oculta el fallo de envío de bienvenida cuando la cuenta se creó pero el correo no se envió.
- `lib/views/orders/external_orders_screen.dart`: solicitudes para llevar y delivery con catálogo, cantidades, datos del cliente, dirección y estado de preparación. Se accede desde el menú del rol.
- `supabase/migrations/20261108_pedidos_externos.sql`: tabla de pedidos externos, políticas RLS y función de transición de estado verificada en servidor.

## Lo que ya existía y se conserva

- Precuenta sin aplicar un pago.
- Apertura de caja con S/ 0 (sin monto inicial automático de S/ 200).
- El administrador crea personal con contraseña temporal, edita identidad y rol, y solicita el enlace de recuperación al correo existente.
- Los empleados no tienen botón propio de cambio o recuperación en la aplicación.
- La función segura de Supabase `administrar-usuarios` valida rol administrativo para esas acciones.

## Configuración indispensable antes de pruebas remotas

1. Ejecutar `supabase/migrations/20261108_pedidos_externos.sql` en el proyecto Supabase de **pruebas** y revisar permisos antes de producción.
2. Desplegar `supabase/functions/administrar-usuarios/index.ts` con validación JWT, nunca incorporar `service_role` en Flutter o GitHub público.
3. Configurar SMTP y plantilla de recuperación de Supabase Auth. La misma plantilla sirve para bienvenida con enlace de establecimiento de contraseña y para recuperación; se pueden diseñar experiencias personalizadas mediante un backend de correo transaccional.
4. Revisar las reglas de recuperación de Supabase Auth a nivel servidor: ocultar el botón en el cliente **no impide** solicitar un enlace mediante el endpoint público de Supabase.
5. Ejecutar `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test` y probar los flujos reales con dos dispositivos.

## Restricciones que no deben confundirse con funciones completas

- Los pedidos externos constituyen un flujo **separado** de los pedidos por mesa. No generan todavía notas fiscales, cobros en `pagos`, stock de cocina ni arqueos automáticos del módulo original. No uses el botón "Entregado" como comprobante de cobro.
- Cuando no se puede enviar el pedido al servidor, queda un **borrador local** en SharedPreferences ligado a la cuenta del navegador actual. El usuario debe pulsar "Sincronizar" para transmitirlo al restablecerse la conexión. No es una cola transaccional completa para todos los módulos ni una sincronización automática en segundo plano.
- El almacenamiento local del navegador puede borrarse y **no comparte** borradores entre distintos equipos. La sincronización solo afecta a pedidos externos; la operación de caja no se debe ejecutar offline sin un diseño de conciliación.
- `flutter analyze` y `flutter test` **no han podido ejecutarse** en este entorno, que no tiene Flutter. La migración SQL tampoco se ha ejecutado en la cuenta Supabase del usuario.
- Un usuario puede seguir invocando endpoints de Supabase Auth directamente si el proyecto no aplica un flujo propio restringido. La autorización del restablecimiento de contraseña necesita endurecimiento adicional del lado servidor si se quiere impedir cualquier recuperación autónoma.

## Seguridad importante

La confirmación presencial es un procedimiento administrativo. La función de restablecimiento debe usar el correo previamente registrado del trabajador. No comunicar contraseñas por correo; preferir enlaces de un solo uso. Ante un cambio de correo, verificar la identidad del trabajador antes de editarlo.

La información del cliente en `pedidos_externos` puede contener teléfonos y direcciones, por lo que se deben definir plazos de conservación, accesos mínimos y cumplimiento legal aplicable antes de producción.

## Alternativas para los mensajes de acceso

- **Supabase Auth + SMTP propio** (recomendado para la primera puesta en marcha): correo de recuperación manejado por Auth, con plantilla configurable desde el panel. Para un nuevo usuario, este proyecto crea la cuenta y solicita un enlace de recuperación para establecer su contraseña. Es un flujo de acceso seguro, pero **el asunto y contenido aún no son una plantilla de bienvenida distinta**.
- **Servicio transaccional como Resend**: permitiría una bienvenida y una recuperación con asuntos y HTML independientes, usando una Edge Function que genere enlaces de Auth y realice el envío con credenciales privadas de servidor. Esta variante no está implementada en el ZIP, y requiere configurar un dominio de envío.

Referencias técnicas: https://supabase.com/docs/guides/auth/auth-smtp ; https://supabase.com/docs/guides/auth/auth-email-templates ; https://resend.com/features/email-api
