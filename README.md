# Retro Cam 📷

App de cámara retro para Android con varios "cámaras"/filtros (Kodak 400,
VHS, Blanco y Negro, Sepia Vintage, Cross Process), grano de película y
viñeta, optimizada para no trabar el preview ni la UI al capturar.

## Estructura del proyecto

```
lib/
  main.dart                     # Punto de entrada
  models/camera_preset.dart     # Definición de cada "cámara" (matriz de color, viñeta, grano)
  widgets/vignette_painter.dart # Overlay de viñeta (barato, RadialGradient)
  widgets/grain_painter.dart    # Overlay de grano (textura precalculada UNA vez)
  utils/photo_processor.dart    # Procesamiento pesado de la foto final, en isolate
  screens/camera_screen.dart    # Pantalla principal: preview + selector + captura
```

## 1. Requisitos previos

Necesitas tener instalado, en tu computadora (Windows, Mac o Linux):

1. **Flutter SDK** → https://docs.flutter.dev/get-started/install
2. **Android Studio** (trae el Android SDK y un emulador) → https://developer.android.com/studio
3. Verifica que todo esté bien configurado corriendo en una terminal:
   ```bash
   flutter doctor
   ```
   Soluciona cualquier "✗" que te marque (normalmente son licencias de
   Android o falta el SDK) antes de continuar.

## 2. Crear el proyecto y copiar el código

```bash
flutter create retro_cam
cd retro_cam
```

Ahora **reemplaza** el archivo `pubspec.yaml` y la carpeta `lib/` que generó
`flutter create` por los que te entregué en este chat (misma estructura de
carpetas: `lib/models`, `lib/widgets`, `lib/screens`, `lib/utils`).

Instala las dependencias:

```bash
flutter pub get
```

## 3. Configurar permisos de Android (importante)

Abre `android/app/src/main/AndroidManifest.xml` y agrega, dentro de la
etiqueta `<manifest>` (fuera de `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

## 4. Configurar la versión mínima de Android

Abre `android/app/build.gradle` (o `android/app/build.gradle.kts` si tu
proyecto usa Kotlin DSL) y asegúrate de que:

```gradle
minSdkVersion 21   // requerido por el paquete `camera`
```

Si usas Kotlin DSL (`build.gradle.kts`), sería:

```kotlin
minSdk = 21
```

## 5. Probar en un dispositivo o emulador

Conecta tu celular Android por USB (con "Depuración USB" activada en
Opciones de desarrollador) o abre un emulador desde Android Studio, y
corre:

```bash
flutter run
```

## 6. Generar el APK final

Para un APK universal (más simple de compartir, pero más pesado):

```bash
flutter build apk --release
```

El archivo queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Recomendado** — para un APK bastante más liviano (genera uno por
arquitectura de procesador):

```bash
flutter build apk --release --split-per-abi
```

Esto genera 3 APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) en la misma
carpeta; para instalar en un celular real normalmente necesitas el de
`arm64-v8a`, que es el más común hoy en día.

Para subir a Google Play en vez de compartir el APK directo, en cambio
generarías un **App Bundle**:

```bash
flutter build appbundle --release
```

## 7. Optimizaciones ya incluidas en el código

- **Filtros de color en el preview**: se aplican con `ColorFilter.matrix`,
  que corre en la GPU vía Skia — no hay procesamiento manual de píxeles en
  Dart durante el preview en vivo, por eso no hay lag.
- **Grano de película precalculado**: la textura de ruido se genera una
  sola vez al abrir la cámara (`GrainPainter.generateNoiseTile`) y se
  reutiliza en cada frame como un shader tileado, en vez de generar ruido
  aleatorio 60 veces por segundo.
- **Procesamiento final en isolate**: al tomar la foto, el filtrado
  píxel-por-píxel (más pesado, porque es en la imagen a resolución
  completa) corre con `compute()` en un isolate separado, así la UI nunca
  se congela ni sientes que la app "se pega" al presionar el botón.
- **`RepaintBoundary`** alrededor del preview: evita que sus repintados
  (que ocurren muy seguido, por ser video en vivo) obliguen a redibujar el
  resto de la pantalla (selector de presets, botones).
- **Ciclo de vida de la cámara manejado correctamente**: se libera la
  cámara (`dispose`) cuando la app pasa a segundo plano y se reinicia al
  volver, evitando fugas de memoria y errores de "cámara ocupada".

## 8. Posibles siguientes pasos

- Agregar más "cámaras" es tan simple como añadir un nuevo
  `CameraPreset` en `lib/models/camera_preset.dart`.
- Si en algún momento quieres un rendimiento aún mayor en el preview
  (por ejemplo, si agregas efectos más complejos como distorsión de
  lente o fugas de luz animadas), lo ideal es migrar los filtros a
  shaders GLSL con el paquete `flutter_shaders`, para que corran 100%
  en GPU.
- Agregar un botón de flash y control de zoom (el paquete `camera` ya
  expone `setFlashMode` y `setZoomLevel` en el `CameraController`).
