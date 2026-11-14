# Fotografías de platillos (foto_url)

- El catálogo obtiene `foto_url` de `platillos` en Supabase y lo almacena en `MenuItem.imageUrl`.
- Las tarjetas de Mesero y Administración muestran la URL con `Image.network`; cuando no existe o falla se conserva la ilustración de respaldo.
- Administración > Catálogo > Nuevo/Editar platillo permite guardar una URL HTTP(S) en `foto_url`.
- No se alteran precios, pedidos, roles, permisos ni caja.
- La URL debe ser pública y accesible por navegador. En páginas Flutter Web, el proveedor debe permitir cargar la imagen desde la página; si no, se mostrará el respaldo.
- No se requiere nueva migración SQL si `platillos.foto_url` ya existe.
- Pendiente: ejecutar Flutter Analyze, tests y probar fotos reales contra Supabase.
