import 'dart:math' as math;
import 'package:flutter/material.dart';

class LuxuryIngredientBackdropPainter extends CustomPainter {
  const LuxuryIngredientBackdropPainter({this.mobile = false});

  final bool mobile;

  @override
  void paint(Canvas canvas, Size size) {
    final darkPanelLeft = mobile ? 0.0 : size.width * .4;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(darkPanelLeft, 0, size.width, size.height));

    final greens = [
      const Color(0xFF648D37),
      const Color(0xFF7FA649),
      const Color(0xFF3E6A32),
    ];
    final topStems = mobile
        ? [
            (size.width * .22, -.01, .08, .13),
            (size.width * .51, -.02, .10, .17),
            (size.width * .78, -.01, -.04, .15),
          ]
        : [
            (size.width * .415, -.02, .02, .13),
            (size.width * .45, -.02, .04, .16),
            (size.width * .485, -.02, .055, .12),
          ];

    for (var index = 0; index < topStems.length; index++) {
      final (x, y, dx, dy) = topStems[index];
      final base = Offset(x, y * size.height);
      final tip = Offset(x + dx * size.width, dy * size.height);
      final stem = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx + dx * size.width * .12,
          size.height * dy * .58,
          tip.dx,
          tip.dy,
        );
      canvas.drawPath(
        stem,
        Paint()
          ..color = greens[index % greens.length].withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = mobile ? 2 : 3
          ..strokeCap = StrokeCap.round,
      );

      for (final step in [.34, .68]) {
        final origin = Offset(
          base.dx + (tip.dx - base.dx) * step,
          base.dy + (tip.dy - base.dy) * step,
        );
        final side = step == .47 ? -1.0 : 1.0;
        _drawLeaf(
          canvas,
          origin,
          angle: math.pi / 2 + side * (.28 + index * .035),
          length: size.width * (mobile ? .045 : .025),
          width: size.width * (mobile ? .012 : .009),
          color: greens[(index + 1) % greens.length],
        );
      }
    }

    final garnish = mobile
        ? [
            (.18, .86, const Color(0xFF789548)),
            (.82, .91, const Color(0xFF668438)),
            (.63, .76, const Color(0xFF779243)),
          ]
        : [
            (.44, .86, const Color(0xFF789548)),
            (.91, .86, const Color(0xFF668438)),
          ];

    for (final (x, y, color) in garnish) {
      final origin = Offset(size.width * x, size.height * y);
      _drawLeaf(
        canvas,
        origin,
        angle: -.65,
        length: size.width * (mobile ? .065 : .032),
        width: size.width * (mobile ? .018 : .009),
        color: color,
      );
      _drawLeaf(
        canvas,
        origin.translate(size.width * .012, 0),
        angle: 2.45,
        length: size.width * (mobile ? .055 : .027),
        width: size.width * (mobile ? .016 : .008),
        color: color.withValues(alpha: .8),
      );
    }

    final specks = mobile
        ? [
            (.1, .77, 3.0, const Color(0xFFE78C38)),
            (.9, .8, 2.4, const Color(0xFF9C4938)),
            (.72, .96, 2.2, const Color(0xFFA5A080)),
            (.27, .94, 2.0, const Color(0xFF668438)),
          ]
        : [
            (.47, .84, 3.0, const Color(0xFFE78C38)),
            (.52, .92, 2.4, const Color(0xFF9C4938)),
            (.71, .87, 2.2, const Color(0xFFA5A080)),
            (.83, .95, 2.0, const Color(0xFF668438)),
            (.93, .73, 2.2, const Color(0xFFE78C38)),
            (.55, .08, 2.0, const Color(0xFF6D8B42)),
          ];

    for (final (x, y, radius, color) in specks) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        radius,
        Paint()..color = color.withValues(alpha: .75),
      );
    }

    canvas.restore();
  }

  void _drawLeaf(
    Canvas canvas,
    Offset start, {
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    final normal = Offset(-direction.dy, direction.dx);
    final tip = start + direction * length;
    final middle = Offset.lerp(start, tip, .52)!;
    final leaf = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        middle.dx + normal.dx * width,
        middle.dy + normal.dy * width,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        middle.dx - normal.dx * width,
        middle.dy - normal.dy * width,
        start.dx,
        start.dy,
      );
    canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: .9));
    canvas.drawLine(
      start,
      tip,
      Paint()
        ..color = const Color(0xFFB4C47A).withValues(alpha: .45)
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(LuxuryIngredientBackdropPainter oldDelegate) =>
      mobile != oldDelegate.mobile;
}

