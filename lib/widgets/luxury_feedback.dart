import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Confirmación uniforme: no presenta éxitos hasta que la operación terminó.
class LuxuryFeedback {
  /// Mensajes de soporte sin exponer trazas, códigos SQL ni datos internos.
  static String message(Object error) {
    if (error is AuthException) {
      return 'No se pudo verificar la sesión. Vuelve a ingresar o consulta al administrador.';
    }
    if (error is PostgrestException) {
      if (error.code == '42501' || error.message.toLowerCase().contains('permission')) {
        return 'No tienes autorización para esta acción. Solicita ayuda al administrador.';
      }
      return 'No se pudo guardar la información. Comprueba la conexión y vuelve a intentarlo.';
    }
    if (error is StateError) {
      final description = error.message.toString();
      if (description.isNotEmpty && !description.contains('Exception') &&
          !description.contains(' at ') && description.length < 210) {
        return description;
      }
    }
    return 'No se pudo completar la operación. Revisa los datos o la conexión e inténtalo nuevamente.';
  }

  static Future<void> success(BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(radius: 36, backgroundColor: Color(0xFFEAF4E3),
                  child: Icon(Icons.check_rounded, size: 42, color: Color(0xFF517B34))),
                const SizedBox(height: 18),
                Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF70675E), height: 1.4)),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Continuar'),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: const Color(0xFF9A3830),
      duration: const Duration(seconds: 5),
      showCloseIcon: true,
    ));
  }
}
