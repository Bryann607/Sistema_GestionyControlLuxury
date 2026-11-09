import 'package:flutter/material.dart';
import 'package:luxury_app/core/theme/app_colors.dart';

/// Encabezado editorial reutilizable, adaptable a móvil y escritorio.
class LuxuryBanner extends StatelessWidget {
  const LuxuryBanner({super.key, required this.eyebrow, required this.title,
    required this.description, this.icon = Icons.restaurant_menu_rounded});

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 22),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1D2022), Color(0xFF34221D), Color(0xFF59341F)]),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Stack(children: [
      Positioned(right: -30, top: -42, child: Icon(icon, size: 185,
        color: const Color(0xFFFCB45F).withValues(alpha: .10))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 27),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow.toUpperCase(), style: const TextStyle(color: luxuryGold,
              fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: MediaQuery.sizeOf(context).width < 650 ? 22 : 28)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Color(0xFFE5D3C5),
              fontSize: 13, height: 1.5)),
          ])),
          if (MediaQuery.sizeOf(context).width > 760) ...[
            const SizedBox(width: 16),
            Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(
              color: const Color(0xFFFCB45F).withValues(alpha: .14),
              borderRadius: BorderRadius.circular(19)),
              child: Image.asset('assets/branding/luxury_logo.png', width: 69, height: 69)),
          ],
        ])),
    ]),
  );
}
