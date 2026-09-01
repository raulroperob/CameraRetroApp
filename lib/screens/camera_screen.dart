import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/camera_preset.dart';
import '../utils/photo_processor.dart';
import '../widgets/grain_painter.dart';
import '../widgets/vignette_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  CameraPreset _selectedPreset = kCameraPresets.first;
  ui.Image? _noiseTile;
  bool _isCapturing = false;
  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = 'Se necesita permiso de cámara.');
      return;
    }
    // Se genera UNA sola vez, se reutiliza en cada frame del preview.
    _noiseTile = await GrainPainter.generateNoiseTile();

    try {
      _cameras = await availableCameras();
    } catch (e) {
      setState(() => _errorMessage = 'No se encontraron cámaras.');
      return;
    }
    if (_cameras.isEmpty) {
      setState(() => _errorMessage = 'No se encontraron cámaras.');
      return;
    }
    await _initController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _initController(CameraDescription description) async {
    final oldController = _controller;
    // ResolutionPreset.high es un buen balance calidad/rendimiento para
    // preview en vivo con filtros; si el dispositivo es gama baja,
    // considera bajar a ResolutionPreset.medium.
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await oldController?.dispose();
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Error al iniciar la cámara: $e');
      setState(() => _errorMessage = 'No se pudo iniciar la cámara.');
      return;
    }
    if (!mounted) return;
    setState(() => _isReady = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isReady = false);
    await _initController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      // compute() ejecuta el procesamiento pesado en OTRO isolate:
      // la UI sigue respondiendo mientras se aplica el filtro final.
      await compute(
        processAndSavePhoto,
        ProcessRequest(file.path, _selectedPreset),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto guardada en la galería')),
        );
      }
    } catch (e) {
      debugPrint('Error al capturar/guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la foto')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isReady || _controller == null || _noiseTile == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // RepaintBoundary aísla el preview + filtros para que sus
              // repintados no obliguen a redibujar el resto del árbol
              // de widgets (selector de presets, botones, etc.).
              child: RepaintBoundary(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColorFiltered(
                          colorFilter:
                              ColorFilter.matrix(_selectedPreset.colorMatrix),
                          child: CameraPreview(_controller!),
                        ),
                        CustomPaint(
                          painter:
                              VignettePainter(_selectedPreset.vignetteStrength),
                        ),
                        CustomPaint(
                          painter: GrainPainter(
                            strength: _selectedPreset.grainStrength,
                            noiseTile: _noiseTile!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildPresetSelector(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kCameraPresets.length,
        itemBuilder: (context, index) {
          final preset = kCameraPresets[index];
          final isSelected = preset.id == _selectedPreset.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPreset = preset),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                preset.name,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 48),
          GestureDetector(
            onTap: _isCapturing ? null : _capture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _isCapturing ? Colors.grey : Colors.white24,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
            onPressed: _switchCamera,
          ),
        ],
      ),
    );
  }
}
