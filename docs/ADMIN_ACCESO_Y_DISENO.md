# Cambios de acceso y presentación

- Los empleados ya no pueden solicitar enlaces de recuperación desde el formulario de inicio, ni actualizar su contraseña desde el menú de cuenta.
- El administrador valida presencialmente la solicitud y usa **Usuarios > Enviar enlace de restablecimiento**. La función `administrar-usuarios` consulta el correo almacenado y solicita a Supabase Auth el envío de un enlace; nunca se transmite una contraseña por correo.
- La creación de usuarios conserva la contraseña temporal definida por el administrador y solicita un correo para establecer una contraseña propia. Para personalizar el mensaje de bienvenida, editar la plantilla **Reset Password** en **Supabase > Authentication > Email Templates** y configurar SMTP. La creación de cuentas sin correo de entrega puede reportar `emailSent: false`; revise los logs.
- Despliegue: `supabase functions deploy administrar-usuarios`. Revise los dominios y las URL de redirección de autenticación.
- Se movió cerrar sesión y la identidad del empleado al menú lateral. En pantallas pequeñas el lateral se abre con el botón de menú superior.

## Limitación importante

Ocultar la opción de restablecimiento en Flutter **no impide por sí solo** que un empleado invoque el endpoint público de recuperación de Supabase desde otro cliente. Para imponer la política de autorización administrativa a nivel de seguridad se necesita un flujo de autenticación personalizado o restringir la recuperación pública a nivel servidor/proveedor. Además, un enlace enviado por Supabase permite al usuario establecer la nueva contraseña, lo cual es necesario para completar la recuperación. Esta implementación restringe la interfaz de trabajo y la función administrativa, no garantiza la prohibición universal del cambio de contraseña.

## Validación

Ejecutar `flutter analyze --no-fatal-infos` y `flutter test` en el proyecto local o GitHub Actions. Los correos reales deben probarse contra una instancia Supabase configurada; aquí no se ejecutaron pruebas de entrega SMTP.
