import 'package:flutter/material.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/views/auth/login_screen.dart';
import 'package:luxury_app/views/work_screen.dart';
import 'package:luxury_app/widgets/widgets.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key, required this.store, this.startupError});
  final RestaurantStore store;
  final String? startupError;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      if (store.loading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: luxuryGold)),
        );
      }
      if (startupError != null) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorBanner(message: startupError!),
              ),
            ),
          ),
        );
      }
      if (store.role == null) return LoginScreen(store: store);
      return WorkScreen(store: store);
    },
  );
}
