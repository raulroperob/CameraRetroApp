import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RetroCamApp());
}

class RetroCamApp extends StatelessWidget {
  const RetroCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Retro Cam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CameraScreen(),
    );
  }
}
