import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Dibuja grano de película tileando una textura de ruido pequeña.
///
/// CLAVE DE OPTIMIZACIÓN: la textura de ruido (`noiseTile`) se genera
/// UNA SOLA VEZ al iniciar la pantalla de cámara (ver [generateNoiseTile]),
/// no en cada frame. Pintarla es solo una operación de shader tileado,
/// muy barata para la GPU, así el preview se mantiene fluido.
class GrainPainter extends CustomPainter {
  final double strength; // 0.0 - 1.0
  final ui.Image noiseTile;

  const GrainPainter({required this.strength, required this.noiseTile});

  /// Genera una textura de ruido en escala de grises de [size]x[size].
  /// Llamar una sola vez y reutilizar la imagen resultante.
  static Future<ui.Image> generateNoiseTile({int size = 64}) async {
    final random = Random();
    final bytes = Uint8List(size * size * 4);
    for (int i = 0; i < size * size; i++) {
      final value = random.nextInt(256);
      final offset = i * 4;
      bytes[offset] = value;
      bytes[offset + 1] = value;
      bytes[offset + 2] = value;
      bytes[offset + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      size,
      size,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );
    return completer.future;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final rect = Offset.zero & size;
    final shader = ImageShader(
      noiseTile,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );
    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.overlay
      ..colorFilter = ColorFilter.mode(
        Colors.white.withOpacity(strength.clamp(0.0, 1.0) * 0.5),
        BlendMode.dstIn,
      );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant GrainPainter oldDelegate) =>
      oldDelegate.strength != strength || oldDelegate.noiseTile != noiseTile;
}
