import 'package:flutter/material.dart';
import 'package:luxury_app/models/menu_item.dart';
import 'package:luxury_app/core/theme/app_colors.dart';

class LuxuryDishArtwork extends StatelessWidget {
  const LuxuryDishArtwork({super.key, required this.item, this.compact = false});

  final MenuItem item;
  final bool compact;

  static const _backgrounds = [
    Color(0xFFF0D7BD),
    Color(0xFFE7D8B7),
    Color(0xFFE9C7B5),
    Color(0xFFD8E1C5),
    Color(0xFFE7D1D8),
  ];
  static const _accents = [
    Color(0xFFC65C36),
    Color(0xFF77914B),
    Color(0xFFE6A13A),
    Color(0xFF87443A),
    Color(0xFFD87C57),
  ];

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl.trim();
    final uri = Uri.tryParse(url);
    final validUrl = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    if (validUrl) {
      return Image.network(
        url,
        width: compact ? 48 : null,
        height: compact ? 48 : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackArtwork(),
      );
    }
    return _fallbackArtwork();
  }

  Widget _fallbackArtwork() {
    final seed = item.id.abs();
    final background = _backgrounds[seed % _backgrounds.length];
    final accent = _accents[seed % _accents.length];
    final category = item.category.toLowerCase();
    final name = item.name.toLowerCase();
    final icon = category.contains('bebida') || name.contains('jugo')
        ? Icons.local_drink_outlined
        : category.contains('postre') || name.contains('helado')
        ? Icons.cake_outlined
        : category.contains('sopa') || name.contains('caldo')
        ? Icons.ramen_dining
        : name.contains('pollo') || name.contains('carne')
        ? Icons.kebab_dining
        : name.contains('arroz') || name.contains('chaufa')
        ? Icons.rice_bowl
        : name.contains('wontan') ||
              name.contains('wantan') ||
              name.contains('roll')
        ? Icons.lunch_dining
        : Icons.restaurant_menu;

    return Container(
      width: compact ? 48 : null,
      height: compact ? 48 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [background.withValues(alpha: .6), luxuryBone],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: compact ? -10 : -20,
            top: compact ? -12 : -25,
            child: Container(
              width: compact ? 35 : 100,
              height: compact ? 35 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .32),
              ),
            ),
          ),
          Container(
            width: compact ? 36 : 94,
            height: compact ? 36 : 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFDFC),
              border: Border.all(color: const Color(0xFFE8DED6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: luxuryBrown.withValues(alpha: .12),
                  blurRadius: compact ? 4 : 12,
                  offset: Offset(0, compact ? 2 : 5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: compact ? 27 : 74,
                height: compact ? 27 : 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background.withValues(alpha: .72),
                ),
                child: Icon(icon, size: compact ? 18 : 46, color: luxuryBrown),
              ),
            ),
          ),
          if (!compact) ...[
            Positioned(
              left: 18,
              bottom: 20,
              child: _LuxuryGarnishDot(color: accent, size: 12),
            ),
            Positioned(
              right: 24,
              top: 18,
              child: _LuxuryGarnishDot(color: luxuryGreen, size: 9),
            ),
            Positioned(
              right: 34,
              bottom: 24,
              child: _LuxuryGarnishDot(color: luxuryGold, size: 7),
            ),
          ],
        ],
      ),
    );
  }
}

class _LuxuryGarnishDot extends StatelessWidget {
  const _LuxuryGarnishDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

