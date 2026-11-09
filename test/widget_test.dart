import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:luxury_app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Supabase exige acceso con cuenta y no ofrece roles demo', (
    tester,
  ) async {
    late SupabaseClient client;
    await tester.runAsync(() async {
      client = SupabaseClient(
        'https://test.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) async => http.Response('{}', 400)),
      );
    });
    await tester.pumpWidget(LuxuryApp(client: client));
    await tester.pumpAndSettle();
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget);
    expect(find.text('CONTRASEÑA'), findsOneWidget);
    expect(
      find.text('Elige el espacio de trabajo para recorrer la demostración.'),
      findsNothing,
    );
    expect(find.textContaining('Modo local de demostración:'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(client.dispose);
  });
}
