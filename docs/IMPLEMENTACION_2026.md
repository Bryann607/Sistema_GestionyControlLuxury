# Cambios y guía de activación (08-11-2026)

## Cambios incluidos en código

- La caja de prueba arranca cerrada y sin fondo predeterminado. La apertura permite S/ 0.00; el importe queda reflejado en `turnos_caja.monto_apertura` cuando está conectado. Los datos DEMO anteriores guardados en el navegador conservan su historial: usar **Reiniciar demostración** para partir de cero.
- **Precuenta**: botón en Caja > Cuentas y cobros para imprimir un PDF informativo que muestra productos, abonos y saldo. No registra cobro ni emite una nota de venta ni comprobante SUNAT.
- **Administración > Usuarios**: nuevo usuario con nombre, correo, rol y contraseña temporal, editar nombre/correo/rol y restablecer contraseña. La edición local se aplica solo a la demo. El alta, el cambio de contraseña y el reseteo conectados necesitan desplegar la función de servidor incluida.
- **Cuenta > Cambiar contraseña** y **Login > ¿Olvidaste tu contraseña?** usan Supabase Auth; el envío de emails requiere un SMTP transaccional configurado.
- Se incluyó el logotipo del restaurante y se renovó el acceso, encabezado y tema manteniendo marrón, oro, rojo y crema.

## Paso indispensable: desplegar función segura

La UI no tiene llave secreta y **no podrá crear usuarios conectados hasta desplegar** `supabase/functions/administrar-usuarios/index.ts` en el proyecto Supabase al que apunta `config/supabase.public.json`.

Desde una máquina con Supabase CLI y acceso autorizado a ese proyecto:

```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase functions deploy administrar-usuarios
```

Mantener la verificación JWT **activada**. La función valida la identidad usando el token del usuario y exige un perfil `public.usuarios` activo de rol `ADMINISTRADOR`. Requiere la clave secreta **solo como variable segura en el servidor**. Nunca poner `SUPABASE_SERVICE_ROLE_KEY` en GitHub, Dart o `config/supabase.public.json`.

La tabla `public.usuarios` debe tener columnas `id`, `nombre_completo`, `correo`, `rol`, `activo` y el usuario que administra debe tener rol `ADMINISTRADOR`. Verificar que no haya trigger que inserte automáticamente un perfil antes que la función: si lo hay, cambiar la inserción a un upsert compatible y revisar sus políticas de acceso.

### Envío de mensajes

- Alta: el admin proporciona contraseña temporal; el servidor crea usuario en Auth y perfil en `usuarios`; después pide a Supabase un email **de recuperación** para que la persona defina una contraseña personal. El sistema no envía la contraseña temporal en texto claro. Si falla el SMTP, la cuenta sigue creada; revisar registro de la función y reenviar recuperación.
- Recuperación: botón del login llama `resetPasswordForEmail`; los correos usan el template **Reset Password** de Supabase.
- Cambio propio: perfil > Cambiar contraseña llama `auth.updateUser`.
- Recuperación en la app publicada: configurar **Authentication > URL Configuration** (Site URL y redirect URLs del dominio GitHub Pages) y en **Authentication > SMTP Settings** un proveedor real. Confirmar que el enlace de recuperación regresa a la aplicación y que ésta restaura la sesión, después cambiar desde el menú de usuario. Para un flujo productivo se recomienda una pantalla dedicada que reaccione al evento `passwordRecovery`.

## Importante: trabajo todavía pendiente

**Delivery / para llevar:** no se incluyó una creación de pedidos real para estos canales. El esquema y RPC `crear_pedido` existente trabajan con mesas físicas, y inventar IDs o escribir pedidos sin una migración SQL dañaría la integridad de inventario/cocina/caja. Diseñar campos `tipo_servicio` (`SALON`, `DELIVERY`, `RECOJO`), cliente, teléfono, dirección, costo de envío, canal, estado de reparto, y actualizar la RPC con transacción, RLS, Realtime y tests multicliente antes de habilitarlo.

**Sin conexión:** la demo local ya persiste en SharedPreferences, pero eso **no es** un sistema offline sincronizado para usuarios conectados. Para garantizar pedidos sin duplicados, se necesita una cola local persistente (IndexedDB en Flutter Web o SQLite en móvil), UUID de idempotencia por transacción, timestamp de revisión, detección de conflictos, reintentos confirmados por servidor, panel de pendientes y política de resolución de diferencias. Evitar sincronizar pagos y cambios de stock sin confirmación autorizada del servidor. No existe una sincronización automática fiable con estos cambios.

**Validación:** no se ejecutaron `flutter analyze`/`flutter test` en este entorno porque Flutter SDK no está instalado. Hacer ambas verificaciones en la máquina local o CI; probar específicamente las políticas RLS y los emails, la recuperación, el alta, edición y reseteo, y caja S/ 0 en dos sesiones simultáneas. Los cambios locales del ZIP no se han publicado en el GitHub ni desplegado en Supabase.
