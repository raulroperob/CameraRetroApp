/// Representa una "cámara" retro: un preset visual completo.
///
/// [colorMatrix] es una matriz 4x5 (20 valores) compatible con
/// `ColorFilter.matrix` de Flutter y también se reutiliza manualmente
/// en el procesamiento final (ver utils/photo_processor.dart) para que
/// la foto guardada luzca exactamente igual que el preview en vivo.
class CameraPreset {
  final String id;
  final String name;
  final List<double> colorMatrix;
  final double vignetteStrength; // 0.0 - 1.0
  final double grainStrength; // 0.0 - 1.0
  final bool squareCrop;

  const CameraPreset({
    required this.id,
    required this.name,
    required this.colorMatrix,
    this.vignetteStrength = 0.0,
    this.grainStrength = 0.0,
    this.squareCrop = false,
  });
}

const List<double> neutralMatrix = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> sepiaMatrix = [
  0.393, 0.769, 0.189, 0, 0, //
  0.349, 0.686, 0.168, 0, 0, //
  0.272, 0.534, 0.131, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> grayscaleMatrix = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> vhsMatrix = [
  1.2, 0, 0.1, 0, -20, //
  0, 0.9, 0, 0, -10, //
  0.1, 0, 1.3, 0, 10, //
  0, 0, 0, 1, 0, //
];

const List<double> kodakMatrix = [
  1.1, 0, 0, 0, 10, //
  0, 1.05, 0, 0, 5, //
  0, 0, 0.9, 0, -10, //
  0, 0, 0, 1, 0, //
];

const List<double> crossProcessMatrix = [
  1.0, 0.1, 0, 0, 0, //
  0.05, 1.1, 0, 0, 10, //
  0, 0.1, 0.8, 0, -10, //
  0, 0, 0, 1, 0, //
];

/// Lista de "cámaras" disponibles en la app.
/// Agregar una nueva cámara retro es tan simple como añadir un elemento aquí.
final List<CameraPreset> kCameraPresets = [
  const CameraPreset(
    id: 'kodak',
    name: 'Kodak 400',
    colorMatrix: kodakMatrix,
    vignetteStrength: 0.2,
    grainStrength: 0.3,
  ),
  const CameraPreset(
    id: 'vhs',
    name: 'VHS Cam',
    colorMatrix: vhsMatrix,
    vignetteStrength: 0.35,
    grainStrength: 0.5,
  ),
  const CameraPreset(
    id: 'bw',
    name: 'Blanco y Negro',
    colorMatrix: grayscaleMatrix,
    vignetteStrength: 0.3,
    grainStrength: 0.4,
  ),
  const CameraPreset(
    id: 'sepia',
    name: 'Sepia Vintage',
    colorMatrix: sepiaMatrix,
    vignetteStrength: 0.25,
    grainStrength: 0.2,
    squareCrop: true,
  ),
  const CameraPreset(
    id: 'cross',
    name: 'Cross Process',
    colorMatrix: crossProcessMatrix,
    vignetteStrength: 0.2,
    grainStrength: 0.3,
  ),
];
