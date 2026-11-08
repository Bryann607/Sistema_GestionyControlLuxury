# Navegación unificada Luxury — 8 de noviembre de 2026

- `WorkScreen` es la única barra lateral (café) en pantallas grandes.
- Las secciones de cada rol (administración, gerente, mesero, cocina y caja) se muestran en dicha barra. Un controlador `ValueNotifier<int>` conecta la opción seleccionada y las pantallas internas.
- `AdminScreen`, `WaiterScreen`, `KitchenScreen` y `CashierScreen` ocultan sus propios menús (NavigationRail, NavigationBar y desplegable de secciones) **solo si** reciben `navigationController` desde `WorkScreen`.
- Si se abren aisladamente, siguen mostrando la navegación original, para no romper sus usos individuales ni las pruebas de `responsive_test.dart`.
- En anchos menores que 950 píxeles, el menú café aparece como un único `Drawer`, accesible desde el icono del `AppBar`.
- Al pie del panel están los datos de la cuenta y el cierre de sesión. El acceso a delivery y para llevar está en el mismo panel.
- Se conserva la corrección `luxury_banner.dart` para alturas menores que 500 píxeles (incluido 640×360).
- No se han modificado la base de datos ni la lógica de negocio de caja.

## Verificación recomendada

```sh
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

El entorno de empaquetado no contiene Flutter; la compilación y las pruebas automatizadas deben verificarse en GitHub Actions.
