import 'package:flutter/material.dart';

/// Dibuja una viñeta (oscurecimiento en las esquinas) usando un
/// RadialGradient. Es barato en GPU y no requiere recalcular nada
/// en cada frame salvo que cambie la intensidad.
class VignettePainter extends CustomPainter {
  final double strength; // 0.0 - 1.0

  const VignettePainter(this.strength);

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(strength.clamp(0.0, 1.0)),
      ],
      stops: const [0.55, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant VignettePainter oldDelegate) =>
      oldDelegate.strength != strength;
}
