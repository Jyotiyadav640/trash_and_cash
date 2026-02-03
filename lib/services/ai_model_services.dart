import 'package:flutter/services.dart';
//import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../screens/camera_service.dart';

class AIModelService {
  /// 🔹 Singleton pattern (important)
  static final AIModelService instance = AIModelService._internal();
  AIModelService._internal();

  //late Interpreter _interpreter;
  late List<String> _labels;
  bool _modelLoaded = false;
  

  /// 🔹 Load model & labels (CALL ON APP START)
  Future<void> loadModel() async {
    try {
    //  _interpreter = await Interpreter.fromAsset(
     //   'assets/model/waste_model.tflite',
      //);

      final labelsData =
          await rootBundle.loadString('assets/model/labels.txt');

      _labels = labelsData
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      _modelLoaded = true;
      debugPrint('✅ AI Model Loaded Successfully');
    } catch (e) {
      debugPrint('❌ Model load error: $e');
    }
  }

  /// 🔹 Camera se image leke prediction
  Future<Map<String, dynamic>> predictFromCamera() async {
    if (!_modelLoaded) {
      throw Exception('Model not loaded yet');
    }

    if (_labels.isEmpty) {
      throw Exception('Labels not loaded');
    }

    final cameraImage =
        await CameraService.controller!.takePicture();

    final bytes = await cameraImage.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Image decode failed');
    }

    final resized =
        img.copyResize(image, width: 160, height: 160);

    final input = List.generate(
      1,
      (_) => List.generate(
        160,
        (y) => List.generate(
          160,
          (x) {
            final p = resized.getPixel(x, y);
            return [
              p.r / 255.0,
              p.g / 255.0,
              p.b / 255.0,
            ];
          },
        ),
      ),
    );

    final output =
        List.generate(1, (_) => List.filled(_labels.length, 0.0));

    //_interpreter.run(input, output);

    final maxIndex = output[0]
        .indexOf(output[0].reduce((a, b) => a > b ? a : b));

    return {
      "label": _labels[maxIndex],
      "confidence": output[0][maxIndex],
      "recyclable": _isRecyclable(_labels[maxIndex]),
      "points": _calculatePoints(_labels[maxIndex]),
    };
  }

  /// 🔹 Helpers
  bool _isRecyclable(String label) {
    const recyclable = [
      "plastic",
      "paper",
      "glass",
      "metal",
      "aluminum"
    ];
    return recyclable.any(
        (e) => label.toLowerCase().contains(e));
  }

  int _calculatePoints(String label) {
    label = label.toLowerCase();
    if (label.contains("plastic")) return 20;
    if (label.contains("paper")) return 10;
    return 5;
  }
}

