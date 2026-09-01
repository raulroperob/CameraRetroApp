import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;

import '../models/camera_preset.dart';

/// Datos que se envían al isolate. Deben ser objetos simples
/// (compute() los serializa entre isolates).
class ProcessRequest {
  final String imagePath;
  final CameraPreset preset;
  const ProcessRequest(this.imagePath, this.preset);
}

/// Punto de entrada para `compute()`. IMPORTANTE: debe ser una función
/// de nivel superior (top-level), no un método de clase, para que
/// Flutter pueda ejecutarla en un isolate separado.
///
/// Todo el trabajo pesado (recorrer millones de píxeles) ocurre aquí,
/// FUERA del hilo principal de la UI. Así, aunque el filtro tarde unos
/// cientos de milisegundos, la app nunca se congela ni se "traba".
Future<void> processAndSavePhoto(ProcessRequest request) async {
  final bytes = await File(request.imagePath).readAsBytes();
  var image = img.decodeImage(bytes);
  if (image == null) return;

  image = _applyColorMatrix(image, request.preset.colorMatrix);

  if (request.preset.vignetteStrength > 0) {
    image = _applyVignette(image, request.preset.vignetteStrength);
  }
  if (request.preset.grainStrength > 0) {
    image = _applyGrain(image, request.preset.grainStrength);
  }
  if (request.preset.squareCrop) {
    image = _cropToSquare(image);
  }

  final outputBytes = img.encodeJpg(image, quality: 92);
  await Gal.putImageBytes(
    Uint8List.fromList(outputBytes),
    name: 'retro_${DateTime.now().millisecondsSinceEpoch}',
  );
}

/// Aplica la misma matriz de color 4x5 que se usa en el preview en vivo,
/// para que la foto guardada luzca IGUAL a lo que el usuario vio en pantalla.
img.Image _applyColorMatrix(img.Image src, List<double> m) {
  for (final pixel in src) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    pixel.r = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0, 255).round();
    pixel.g = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0, 255).round();
    pixel.b = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0, 255).round();
  }
  return src;
}

img.Image _applyVignette(img.Image src, double strength) {
  final cx = src.width / 2;
  final cy = src.height / 2;
  final maxDist = sqrt(cx * cx + cy * cy);
  for (final pixel in src) {
    final dx = pixel.x - cx;
    final dy = pixel.y - cy;
    final dist = sqrt(dx * dx + dy * dy) / maxDist;
    final factor = (1.0 - (dist * dist * strength)).clamp(0.0, 1.0);
    pixel.r = (pixel.r * factor).clamp(0, 255).round();
    pixel.g = (pixel.g * factor).clamp(0, 255).round();
    pixel.b = (pixel.b * factor).clamp(0, 255).round();
  }
  return src;
}

img.Image _applyGrain(img.Image src, double strength) {
  final random = Random();
  final amount = (strength * 40).round();
  for (final pixel in src) {
    final noise = random.nextInt(amount * 2 + 1) - amount;
    pixel.r = (pixel.r + noise).clamp(0, 255).round();
    pixel.g = (pixel.g + noise).clamp(0, 255).round();
    pixel.b = (pixel.b + noise).clamp(0, 255).round();
  }
  return src;
}

img.Image _cropToSquare(img.Image src) {
  final size = min(src.width, src.height);
  final x = (src.width - size) ~/ 2;
  final y = (src.height - size) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: size, height: size);
}
