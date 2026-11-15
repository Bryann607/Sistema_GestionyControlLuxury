# Arquitectura del proyecto

El proyecto sigue una arquitectura **MVC adaptada a Flutter**, organizada por capas.
`RestaurantStore` es un `ChangeNotifier`: cumple el rol de **controlador** (lógica y estado)
y las vistas se redibujan al escuchar sus cambios.

```
lib/
├── main.dart                  Punto de entrada: inicializa Supabase y lanza la app
├── app.dart                   LuxuryApp: crea el controlador y el MaterialApp
│
├── core/                      Piezas transversales, sin lógica de negocio
│   ├── config/supabase_bootstrap.dart   Lee --dart-define e inicializa Supabase
│   ├── theme/app_colors.dart            Paleta Luxury
│   ├── theme/app_theme.dart             ThemeData de la app
│   └── utils/                           formatters.dart (money), status_colors.dart
│
├── models/                    M — Entidades del dominio (una por archivo)
│   └── models.dart            Archivo "barril": un solo import para todos los modelos
│
├── controllers/               C — Lógica y estado
│   └── restaurant_store.dart  Pedidos, mesas, menú, inventario, caja, personal.
│                              Habla con Supabase (o con datos demo locales)
│
├── services/                  Servicios de apoyo
│   └── receipt_pdf.dart       Generación e impresión de notas de venta en PDF
│
├── views/                     V — Pantallas, agrupadas por rol
│   ├── root_screen.dart       Decide: cargando / error / login / espacio de trabajo
│   ├── work_screen.dart       Barra superior y selección de pantalla según el rol
│   ├── auth/login_screen.dart
│   ├── admin/admin_screen.dart       Administrador y Gerente
│   ├── waiter/waiter_screen.dart     Mesero
│   ├── kitchen/kitchen_screen.dart   Cocinero y Jefe de cocina
│   └── cashier/cashier_screen.dart   Cajero
│
└── widgets/                   Componentes visuales reutilizables (uno por archivo)
    └── widgets.dart           Archivo "barril"
```

## Reglas de dependencia

```
views ──► widgets ──► core
  │                    ▲
  ├──► controllers ────┤
  │        │           │
  └────────┴──► models ┘     services ──► models
```

- `models` no depende de nada de Flutter ni de otras capas.
- `controllers` conoce `models` y Supabase; **no** importa nada de `views`.
- `views` leen y modifican datos **solo** a través del controlador.
- `widgets` y `core` no conocen el controlador.

## Dónde agregar cosas nuevas

| Quiero…                              | Lo hago en…                                            |
|--------------------------------------|--------------------------------------------------------|
| Una nueva entidad (ej. Proveedor)    | `models/proveedor.dart` + exportarla en `models.dart`  |
| Un botón/tarjeta reutilizable        | `widgets/` + exportarlo en `widgets.dart`              |
| Una nueva regla de negocio o consulta| `controllers/restaurant_store.dart`                    |
| Una nueva pantalla de un rol         | `views/<rol>/`                                         |
| Cambiar colores o tema               | `core/theme/`                                          |

## Siguientes pasos recomendados para escalar

1. **Dividir `RestaurantStore`** (≈2.100 líneas) en controladores por dominio
   (`OrdersController`, `InventoryController`, `MenuController`, `CashController`, `StaffController`)
   y una capa `repositories/` que concentre las llamadas a Supabase. Conviene hacerlo con Flutter
   instalado, apoyándose en las pruebas existentes.
2. **Dividir las pantallas grandes** (`admin_screen.dart`, `waiter_screen.dart`, etc.) en un widget por
   sección (`views/admin/sections/menu_section.dart`, …).
3. **Tipar los comprobantes**: hoy `receipts` es `List<Map<String, dynamic>>`; un modelo `Receipt`
   evitaría errores con las claves de texto.
