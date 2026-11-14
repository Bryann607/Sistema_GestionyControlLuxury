# Luxury — integración de versiones (9 de noviembre de 2026)

## Base y alcance
- **Base funcional:** `Sistema_GestionyControlLuxury(7).zip`, con estructura Flutter modular, control de roles, caja, órdenes externas, SQL y workflow de GitHub Pages.
- **Referencia visual:** `Sistema_GestionyControlLuxury-main (3).zip`. Se recuperó el estilo gastronómico y la ilustración de platillos, sin sustituir los controladores o la lógica de negocio actual.
- **Login:** mantiene fondo negro, detalles dorados y logotipo; recupera ornamentos de ingredientes de la versión antigua. Los formularios y acceso siguen usando el controlador actual.
- **Carta:** tarjetas de Mesero y catálogo de Administración usan ilustraciones categorizadas; se conservan precios, disponibilidad, cantidades, observaciones y acciones.
- **Arquitectura:** un solo proyecto Flutter; `pubspec.yaml` en la raíz. No se copian compilaciones `build/`, cachés o `luxury-web/` anteriores.

## Qué NO hace esta integración
- No ejecuta migraciones en Supabase automáticamente, ni modifica el esquema o permisos remotos.
- No garantiza que Delivery haya quedado conectado al flujo ordinario de Cocina/Caja si esto depende del esquema remoto.
- No constituye certificación de pruebas ni publicación: no se dispone del ejecutable Flutter en el entorno donde se creó el archivo.

## Validación obligatoria antes de despliegue
Desde la raíz del repositorio:

```powershell
flutter clean
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome --dart-define-from-file=config/supabase.public.json
```

Verificar con cuentas autorizadas que los procesos de gerente, administrador, mesero, cocina y caja se comportan correctamente, incluyendo apertura de caja, pagos, Delivery, permisos y cierre. No usar producción para pruebas destructivas.

## GitHub Pages
El workflow `.github/workflows/publicar.yml` ejecuta análisis, pruebas y una compilación desde la raíz. El `base-href` existente apunta a `/Sistema_GestionyControlLuxury/`; debe coincidir con el nombre real del repositorio. Configurar Settings > Pages > GitHub Actions. Las migraciones SQL (`supabase/migrations/`) deben revisarse y aplicarse a la base de datos por separado, solo si corresponden.
