# Sistema de Gestión y Control Luxury

Aplicación Flutter conectada al proyecto **SBLuxury** de Supabase.

**Abrir aplicación:** https://andersonbg-hub.github.io/Sistema_GestionyControlLuxury/

## Estructura del repositorio

Este repositorio **es** el proyecto Flutter (`pubspec.yaml` está en la raíz).

- `lib/`: código de la aplicación, organizado en MVC. Ver [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).
- `test/`: pruebas de conexión, acceso y diseño adaptable.
- `web/`: plantilla de la plataforma web.
- `config/supabase.public.json`: URL y clave **publishable** de Supabase.
- `.github/workflows/publicar.yml`: compila la versión web desde el código fuente y la publica en GitHub Pages al actualizar `main`.

Ya no hace falta subir `luxury-web.zip`: la compilación web la genera GitHub Actions en cada publicación.

## Conexión y acceso

El archivo `config/supabase.public.json` contiene la URL y la clave **publishable** del proyecto. Flutter recibe esos valores al compilar; copiar un `.env` a la web publicada no configura por sí solo la aplicación.

En modo conectado, ingresar con una cuenta de **Supabase Auth** que tenga un perfil activo en `public.usuarios`, con el mismo UUID. El campo `rol` controla el espacio de trabajo: `ADMINISTRADOR`, `GERENTE`, `COCINERO`, `JEFE_COCINA`, `MESERO` o `CAJERO`.

La sesión del panel de administración de Supabase es distinta de una cuenta de acceso a Luxury. La clave pública no es la contraseña de un usuario. Los botones de roles de demostración dejan de aparecer al configurar Supabase.

Se verificó que existen las 14 tablas usadas por la aplicación, las 15 funciones RPC que invoca y las seis tablas de su suscripción Realtime. Las tablas tienen RLS habilitado. No se desactivaron esas protecciones ni se incluyeron claves secretas o `service_role` en la web.

La aplicación conectada no carga los datos de ejemplo del navegador. Si falla la carga de datos al iniciar sesión, vuelve al acceso en lugar de mostrar un panel con datos de demostración.

## Crear un acceso de Luxury si fuera necesario

La persona que administra SBLuxury debe:

1. Crear o comprobar la cuenta en **Authentication → Users** y que su correo esté confirmado.
2. Comprobar en **Table Editor → usuarios** que existe el perfil con el mismo `id` de Auth, `nombre_completo`, `correo`, el `rol` correspondiente y `activo = true`.
3. Facilitar las credenciales al integrante por un canal privado. No publicar contraseñas en este repositorio.

## Compilar y actualizar

Con Flutter instalado, desde la raíz del repositorio:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=config/supabase.public.json
flutter build web --release --base-href /Sistema_GestionyControlLuxury/ --dart-define-from-file=config/supabase.public.json
```

Para publicar basta con hacer commit y push a `main`; la pestaña **Actions** muestra el resultado.
Mantener **Settings → Pages → Source → GitHub Actions**.

Compilar sin `--dart-define-from-file` abre el modo local de demostración; no usar esa compilación para reemplazar la versión conectada.

### Otras plataformas (Android, iOS, escritorio)

El código Flutter es multiplataforma, pero el proyecto solo tiene habilitada la carpeta `web/`. Para agregar las demás, ejecutar una vez en la raíz:

```sh
flutter create --platforms=android,ios,windows,macos,linux .
```

Esto agrega las carpetas de plataforma sin tocar `lib/`.

## Verificación

La versión 0.1.2 adapta encabezados y registros al ancho disponible. En pantallas pequeñas, las acciones aparecen debajo de la información; el selector «Sección» permite abrir todos los módulos de administración. Las estadísticas utilizan alturas naturales y las tarjetas del salón conservan espacio para el estado y la capacidad. También se adaptaron las listas de mesero, cocina y caja.

Las pruebas de interfaz recorren las ocho secciones de administración, las tres pestañas de inventario y los espacios de mesero, cocina y caja. Se comprueban anchos de 320, 390, 600, 640, 768, 844 y 1280 píxeles, orientación vertical y horizontal, texto ampliado al 150 %, ausencia de errores de distribución y espacio suficiente para los nombres de los registros. También se abre una comanda y se agrega un producto para comprobar sus controles y desplazamiento. Se ejecutan con datos de demostración locales y no escriben en Supabase.

Se mantienen las tres pruebas de conexión y acceso. Consultar tablas y funciones confirma la estructura; la prueba completa de escritura desde la aplicación requiere iniciar sesión con una cuenta autorizada y autorización para utilizar datos de prueba. La actualización del diseño no cambia datos, tablas, cuentas, funciones ni permisos de Supabase.

## Actualización de usuarios, caja y apariencia (noviembre de 2026)

Lee [docs/IMPLEMENTACION_2026.md](docs/IMPLEMENTACION_2026.md) antes de publicar. Se requieren pasos en Supabase para activar la gestión de usuarios; delivery y sincronización offline quedan especificados como pendientes, no simulados como funcionalidades completas.
