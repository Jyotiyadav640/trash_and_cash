import 'package:camera/camera.dart';

class CameraService {
  static CameraController? controller;
  static List<CameraDescription>? cameras;

  static Future<void> initialize() async {
    cameras = await availableCameras();

    controller = CameraController(
      cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();
  }

  static void dispose() {
    controller?.dispose();
  }
}
