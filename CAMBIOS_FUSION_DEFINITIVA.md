# Fusión definitiva Luxury (VersioNose + Luxury-SIG)

Base: **VersioNose** (diseño de login e interfaces intacto). Funciones tomadas de **Luxury-SIG**.

## Corrección del login
- Causa: al iniciar sesión se cargaban los pedidos con `mesa_id as int`. Los pedidos de delivery / para llevar de la base real tienen `mesa_id` nulo, la carga fallaba, la app cerraba la sesión y mostraba un mensaje genérico aunque las credenciales fueran correctas. Mismo fallo en el cálculo de mesa de las notas de venta.
- Ahora `mesa_id` nulo es válido, y el login muestra el motivo real (credenciales, correo sin confirmar, perfil inactivo, error de carga de datos).

## Funciones incorporadas de Luxury-SIG
- Pantalla de carga web de arranque (con reintento) y barra de progreso dorada al iniciar sesión.
- Diálogo de carga bloqueante en operaciones (`runLuxuryOperation`).
- Carga de datos en paralelo al iniciar sesión.
- Menú desplegable de cuenta (Mi perfil, Actualizar información, Cerrar sesión con confirmación).
- Pedidos para llevar y delivery conectados a la base real (`pedidos.tipo_pedido` + RPC `crear_pedido_sincronizado`); llegan a Cocina y Caja por el flujo normal y se muestran como «Delivery · cliente».
- Migraciones y función `manage-staff` de Luxury-SIG en `supabase/`. Las migraciones de la tabla `pedidos_externos` (que no existe en la base real) quedaron en `supabase/legacy/`.

## Pendiente / no portado
- Cambio de contraseña obligatorio, cola de pedidos sin conexión y reportes avanzados de Luxury-SIG.
- No se pudo compilar aquí (sin Flutter). Ejecutar: `flutter pub get && flutter analyze && flutter test`, luego `flutter run -d chrome --dart-define-from-file=config/supabase.public.json`.

## Segunda ronda
- **Perfil** (como Luxury-SIG): foto de perfil en Supabase Storage (`employee-profiles`) que se guarda al elegirla, y solo datos de contacto básicos vía `actualizar_perfil_propio`. La foto se muestra en el menú de cuenta.
- **Fotos de platillos**: en Administración > Menú, el campo URL se reemplazó por «Subir foto» (galería, JPG/PNG/WebP, máx. 2 MB). Se sube al bucket `dish-photos` y la URL pública se guarda sola en `platillos.foto_url`. **Aplicar `supabase/migrations/20261112000000_Dish_photos_storage.sql` en Supabase** (y las migraciones de Luxury-SIG si aún no están).
- **Pantallas de carga** en todas las operaciones de Administración, Caja, Cocina y Mesero (diálogo bloqueante, evita doble clic).
- **Para llevar y delivery** solo para Mesero y Administrador (quienes pueden registrarlos en la base). Cocina y Caja los reciben en sus pantallas normales como «Delivery · cliente».
- Pendiente: rediseño de la vista del mesero (plano de mesas con sillas) y flujo de consumos adicionales de Luxury-SIG.
