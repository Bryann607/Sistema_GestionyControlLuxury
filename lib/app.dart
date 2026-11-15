import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_theme.dart';
import 'package:luxury_app/views/root_screen.dart';

class LuxuryApp extends StatefulWidget {
  const LuxuryApp({super.key, this.client, this.initializationError});
  final SupabaseClient? client;
  final String? initializationError;

  @override
  State<LuxuryApp> createState() => _LuxuryAppState();
}

class _LuxuryAppState extends State<LuxuryApp> {
  late final RestaurantStore store = RestaurantStore(client: widget.client);

  @override
  void initState() {
    super.initState();
    unawaited(store.initialize());
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Luxury · Restaurante Oriental',
    debugShowCheckedModeBanner: false,
    theme: buildLuxuryTheme(),
    home: RootScreen(store: store, startupError: widget.initializationError),
  );
}
