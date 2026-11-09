import 'package:flutter/widgets.dart';

import 'package:luxury_app/app.dart';
import 'package:luxury_app/core/config/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startup = await initializeSupabase();
  runApp(LuxuryApp(client: startup.client, initializationError: startup.error));
}
