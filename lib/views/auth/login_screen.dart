import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
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
    } catch (exception) {
      setState(() => error = '$exception');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _recoverPassword() async {
    final recoveryEmail = TextEditingController(text: email.text.trim());
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: SizedBox(width: 380, child: TextField(controller: recoveryEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Correo registrado'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, recoveryEmail.text.trim()), child: const Text('Enviar enlace')),
      ],
    ));
    recoveryEmail.dispose();
    if (result == null || result.isEmpty) return;
    try {
      await store.requestPasswordRecovery(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Si el correo está registrado, recibirás instrucciones para recuperar el acceso.'),
        ));
      }
    } catch (exception) {
      if (mounted) setState(() => error = '$exception');
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        return Row(
          children: [
            if (!narrow)
              Expanded(
                child: Container(
                  color: luxuryBrown,
                  padding: const EdgeInsets.all(54),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Container(
                        width: 170, height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: const Color(0xFFFFF8E9),
                          border: Border.all(color: luxuryGold, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
                        ),
                        padding: const EdgeInsets.all(7),
                        child: ClipOval(child: Image.asset('assets/branding/luxury_logo.png', fit: BoxFit.cover)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LUXURY',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sabor oriental. Servicio excepcional.',
                        style: TextStyle(
                          color: Color(0xFFF5D7B8),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Comandas, cocina, caja e inventario en armonía, con una experiencia diseñada para Luxury.',
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      const Spacer(),
                      Text(
                        store.isConnected
                            ? 'SUPABASE · CONECTADO'
                            : 'RESTAURANTE ORIENTAL · CHINCHA',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (narrow) ...[
                          ClipOval(child: Image.asset('assets/branding/luxury_logo.png', width: 84, height: 84, fit: BoxFit.cover)),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          store.isConnected
                              ? 'Bienvenido a Luxury'
                              : 'Bienvenido a Luxury',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.isConnected
                              ? 'Ingresa a tu espacio de trabajo del restaurante.'
                              : 'Elige el espacio de trabajo para recorrer la demostración.',
                        ),
                        const SizedBox(height: 24),
                        if (store.errorMessage != null) ...[
                          ErrorBanner(message: store.errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        if (error != null) ...[
                          ErrorBanner(message: error!),
                          const SizedBox(height: 12),
                        ],
                        if (store.isConnected) ...[
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            onSubmitted: (_) => _signIn(),
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          Align(alignment: Alignment.centerRight, child: TextButton(
                            onPressed: busy ? null : _recoverPassword,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          )),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: busy ? null : _signIn,
                              child: Text(
                                busy ? 'Conectando…' : 'Iniciar sesión',
                              ),
                            ),
                          ),
                        ] else ...[
                          ...StaffRole.values.map(
                            (role) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  onTap: busy ? null : () => _login(role),
                                  leading: CircleAvatar(
                                    backgroundColor: luxuryGold.withValues(
                                      alpha: .15,
                                    ),
                                    child: Icon(
                                      _roleIcon(role),
                                      color: luxuryBrown,
                                    ),
                                  ),
                                  title: Text(
                                    role.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(_roleDescription(role)),
                                  trailing: busy
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 15,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Modo local de demostración: los cambios se conservan en este dispositivo y no se envían a Supabase.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
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
