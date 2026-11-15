import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de intentar conectar con Supabase al arrancar la app.
///
/// - [client] no es nulo cuando la conexión quedó lista.
/// - [error] trae el mensaje a mostrar si la configuración está incompleta o falló.
/// - Si ambos son nulos, la app abre en modo local de demostración.
class SupabaseStartup {
  const SupabaseStartup({this.client, this.error});
  final SupabaseClient? client;
  final String? error;
}

/// Lee `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` (valores `--dart-define`)
/// e inicializa Supabase. Ver `config/supabase.public.json`.
Future<SupabaseStartup> initializeSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  if (url.isEmpty && publishableKey.isEmpty) return const SupabaseStartup();
  if (url.isEmpty || publishableKey.isEmpty) {
    return const SupabaseStartup(
      error:
          'Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY juntos para habilitar la conexión.',
    );
  }
  try {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    return SupabaseStartup(client: Supabase.instance.client);
  } catch (error) {
    return SupabaseStartup(error: 'No se pudo inicializar Supabase: $error');
  }
}
