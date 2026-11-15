# Luxury — Perfil, confirmaciones y pedidos externos

## Cambios de esta entrega

- Perfil universal accesible al pulsar la identidad del usuario en el menú lateral; diseño adaptable y desplazamiento interno.
- Consulta de nombre, cargo, estado e identificador desde el perfil operativo `usuarios` (solo lectura).
- Edición de datos de contacto opcionales, área y URL HTTPS de fotografía mediante metadatos privados de **Supabase Auth** del usuario autenticado. No se altera `rol`, `activo`, `dni`, ni credenciales. No existe subida de archivos de fotografía; debe pegarse una URL HTTPS accesible.
- Mensajes de confirmación estandarizados con animación ligera en comandas y cambios de estado de pedidos externos.
- Mensajes de error más entendibles sin mostrar excepciones técnicas en los principales formularios.
- En pedidos externos, el mesero solo consulta y crea `PARA_LLEVAR`; el cajero y supervisores gestionan `DELIVERY`; Cocina/Jefatura puede consultar pedidos externos y pasar por preparación. Se valida celular peruano de nueve dígitos.
- Nueva migración **`supabase/migrations/20261109_roles_pedidos_externos.sql`** para aplicar la separación de permisos también en Supabase y evitar que el mesero entregue un Delivery por llamada directa a RPC.
- Se mantiene el login oscuro, el catálogo con `foto_url` y el flujo de Caja existente.

## Instalación y pruebas

1. Realizar copia del repositorio actual y de los datos relevantes antes de aplicar migraciones.
2. Reemplazar los archivos del repositorio por los del ZIP corregido. No subir carpetas `build`, `.dart_tool`, `.gradle` ni secretos de servidor.
3. Desde la raíz con `pubspec.yaml`, ejecutar `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test` y `flutter run -d chrome --dart-define-from-file=config/supabase.public.json`.
4. En Supabase SQL Editor, verificar primero que existe `pedidos_externos` y que las migraciones anteriores están instaladas; después ejecutar la nueva migración SQL. **Subir a GitHub no ejecuta SQL**.
5. Probar por rol: Mesero (solo Para llevar), Cajero (Delivery y Para llevar), Cocina (preparación), Administrador (supervisión), Gerente (consulta). Verificar que un pedido no se duplique, que las transiciones sean válidas y que los borradores no se anuncien como enviados.
6. Revisar GitHub Actions y Pages tras el commit.

## Alcance y limitaciones

La actualización de la imagen de perfil depende de una URL externa pública HTTPS; no incluye carga a Supabase Storage. Los datos personales opcionales se almacenan como metadatos del usuario autenticado, no en columnas `usuarios` ni en el catálogo de colaboradores para administración. Los permisos de la nueva migración solo se aplican al ejecutarla en la base de datos correcta. El flujo de `pedidos_externos` sigue separado de las comandas tradicionales del módulo de mesas; para una integración contable total haría falta una validación funcional y SQL adicional.

**Validación pendiente:** En el entorno de creación de este ZIP no está instalado Flutter ni hay conexión a tu Supabase. No se han ejecutado `flutter analyze`, `flutter test` ni las pruebas de la base de datos real. No se debe presentar esta entrega como una certificación libre de errores.
