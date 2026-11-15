import 'dart:async';

import 'package:flutter/material.dart';

import 'package:luxury_app/core/theme/app_colors.dart';
import 'package:luxury_app/widgets/luxury_feedback.dart';

/// Muestra una pantalla de carga central que bloquea el fondo mientras dura [action].
Future<T> showBlockingProgress<T>(
  BuildContext context, {
  required Future<T> Function() action,
  String label = 'Procesando…',
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 368),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('Espera un momento.', textAlign: TextAlign.center),
                const SizedBox(height: 18),
                const LinearProgressIndicator(
                  color: luxuryGold,
                  backgroundColor: Color(0xFFF0E2D3),
                  minHeight: 5,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  unawaited(navigator.push(route));
  try {
    return await action();
  } finally {
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  }
}

/// Ejecuta [action] con pantalla de carga y muestra el error si falla.
Future<bool> runLuxuryOperation(
  BuildContext context,
  Future<void> Function() action, {
  String label = 'Procesando…',
}) async {
  try {
    await showBlockingProgress(context, label: label, action: action);
    return true;
  } catch (error) {
    if (context.mounted) LuxuryFeedback.error(context, LuxuryFeedback.message(error));
    return false;
  }
}
