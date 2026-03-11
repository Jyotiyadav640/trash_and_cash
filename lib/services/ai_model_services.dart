import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';

class AIModelService {
  AIModelService._();
  static final instance = AIModelService._();

  // static const String baseUrl = 'http://192.168.1.100:5000';

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  Future<Map<String, dynamic>> predictFromImage(File image) async {
    print("🌐 Hitting API...");

    final uri = Uri.parse('${AppConstants.baseUrl}/predictch');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );
    print("🔥 predictFromImage CALLED");
print("📸 Image path: ${image.path}");

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('AI Server Error');
    }

    return jsonDecode(body);
    print("✅ API RESPONSE: $body");


  }
}
