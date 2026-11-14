import 'package:luxury_app/widgets/luxury_ingredient_backdrop.dart';
import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});
  final RestaurantStore store;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  RestaurantStore get store => widget.store;

  Future<void> _login(StaffRole role) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await store.loginDemo(role);
    } catch (exception) {
      setState(() => error = '$exception');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await store.signIn(email.text.trim(), password.text);
    } catch (_) {
      if (mounted) {
        setState(() => error =
          'No fue posible iniciar sesión. Verifica tus datos e inténtalo nuevamente.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Cambio exclusivamente visual: se conservan _signIn, _login y sus permisos.
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF141519),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: wide
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: _brandPanel(compact: false)),
                          Expanded(flex: 6, child: _formPanel()),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _brandPanel(compact: true),
                        _formPanel(),
                      ],
                    ),
                  ),
          ),
        );
      },
    ),
  );

  Widget _brandPanel({required bool compact}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 225 : 520),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F5ED), Color(0xFFE9DCC7)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: _decorativeCircle(260),
          ),
          Positioned(
            right: -110,
            bottom: -100,
            child: _decorativeCircle(320),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 22 : 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu, color: Color(0xFF956019), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'LUXURY  ·  RESTAURANTE ORIENTAL',
                      style: TextStyle(color: Color(0xFF553B2B), fontSize: 12,
                          letterSpacing: 1.2, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 44),
                Center(
                  child: Container(
                    height: compact ? 112 : 238,
                    width: compact ? 112 : 238,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFFAF0),
                      border: Border.all(color: const Color(0xFFC78E37), width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x332A1F18), blurRadius: 28,
                          offset: Offset(0, 12))],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/branding/luxury_logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 35),
                Text(
                  'SABOR QUE REÚNE',
                  style: TextStyle(
                    color: const Color(0xFF644129),
                    fontSize: compact ? 19 : 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  const Text('Pedidos, servicio y gestión en un solo lugar.',
                    style: TextStyle(color: Color(0xFF765C49), fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                  const Text('TRADICIÓN  •  CALIDEZ  •  SERVICIO',
                    style: TextStyle(color: Color(0xFF98734E), fontSize: 11,
                        letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x339A713D), width: 2),
      ),
    ),
  );

  Widget _formPanel() => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 520),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF222329), Color(0xFF141519)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: LuxuryIngredientBackdropPainter(mobile: true)),
          ),
        ),
        Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ASIAN FOOD  ·  CHINCHA',
                style: TextStyle(color: Color(0xFFC6A77A), fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 2.5)),
              const SizedBox(height: 25),
              const Text('Iniciar sesión', style: TextStyle(color: Colors.white,
                  fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                store.isConnected
                    ? 'Usa tu cuenta autorizada para ingresar al sistema.'
                    : 'Selecciona un perfil para explorar el sistema en modo demostración.',
                style: const TextStyle(color: Color(0xFFC8C9CB), height: 1.5),
              ),
              const SizedBox(height: 26),
              if (store.errorMessage != null) ...[
                ErrorBanner(message: store.errorMessage!),
                const SizedBox(height: 14),
              ],
              if (error != null) ...[
                ErrorBanner(message: error!),
                const SizedBox(height: 14),
              ],
              if (store.isConnected) ...[
                _loginLabel('CORREO ELECTRÓNICO'),
                const SizedBox(height: 8),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Color(0xFF26201C)),
                  decoration: _loginDecoration('nombre@empresa.com', Icons.alternate_email),
                ),
                const SizedBox(height: 20),
                _loginLabel('CONTRASEÑA'),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  obscureText: true,
                  onSubmitted: (_) => _signIn(),
                  style: const TextStyle(color: Color(0xFF26201C)),
                  decoration: _loginDecoration('Ingresa tu contraseña', Icons.lock_outline),
                ),
                const SizedBox(height: 13),
                const Text('Para recuperar tu acceso, comunícate con el administrador.',
                  style: TextStyle(color: Color(0xFFBEC0C4), fontSize: 12, height: 1.5)),
                const SizedBox(height: 27),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE39A35),
                      foregroundColor: const Color(0xFF211911),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(busy ? 'Ingresando…' : 'Iniciar sesión',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ] else ...[
                ...StaffRole.values.map((role) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: const Color(0xFF303036),
                    child: ListTile(
                      onTap: busy ? null : () => _login(role),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF5F482B),
                        child: Icon(_roleIcon(role), color: const Color(0xFFF0BB6B)),
                      ),
                      title: Text(role.label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      subtitle: Text(_roleDescription(role),
                        style: const TextStyle(color: Color(0xFFC8C9CB))),
                      trailing: busy
                          ? const SizedBox.square(dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward_ios,
                              color: Color(0xFFE0B177), size: 15),
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                const Text('Demostración local: los cambios se conservan solo en este dispositivo.',
                  style: TextStyle(color: Color(0xFFBEC0C4), fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
        ),
      ],
    ),
  );

  Widget _loginLabel(String value) => Text(value,
    style: const TextStyle(color: Color(0xFFEAD1AC), fontSize: 11,
        letterSpacing: 1.1, fontWeight: FontWeight.w700));

  InputDecoration _loginDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF817A75)),
    prefixIcon: Icon(icon, color: const Color(0xFF9D713B)),
    filled: true,
    fillColor: const Color(0xFFFFFAF3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6C4AD))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE39A35), width: 2)),
  );

  static IconData _roleIcon(StaffRole role) => switch (role) {
    StaffRole.administrator => Icons.space_dashboard_outlined,
    StaffRole.manager => Icons.manage_accounts_outlined,
    StaffRole.kitchen => Icons.soup_kitchen_outlined,
    StaffRole.headChef => Icons.restaurant_menu,
    StaffRole.waiter => Icons.table_restaurant,
    StaffRole.cashier => Icons.point_of_sale,
  };

  static String _roleDescription(StaffRole role) => switch (role) {
    StaffRole.administrator =>
      'Dashboard, menú, inventario, usuarios y reportes',
    StaffRole.manager => 'Reportes, incidencias, usuarios y auditoría',
    StaffRole.kitchen => 'Comandas en vivo, disponibilidad y faltantes',
    StaffRole.headChef => 'Comandas, alertas, disponibilidad y solicitudes',
    StaffRole.waiter => 'Mesas, pedidos, observaciones y seguimiento',
    StaffRole.cashier => 'Pagos mixtos, notas de venta y arqueo',
  };
}
