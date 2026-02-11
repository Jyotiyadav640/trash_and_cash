import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';
import 'pickup_request_screen.dart';

class AIWebViewScreen extends StatefulWidget {
  const AIWebViewScreen({super.key});

  @override
  State<AIWebViewScreen> createState() => _AIWebViewScreenState();
}

class _AIWebViewScreenState extends State<AIWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final params = const PlatformWebViewControllerCreationParams();
    final controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setOnShowFileSelector(_pickFile);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (message) {
          // message: proceed|/uploads/img.jpg
          final parts = message.message.split('|');

          if (parts.length == 2 && parts[0] == 'proceed') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PickupRequestScreen(
                  imageUrl: 'http://192.168.0.106:5000${parts[1]}',
                ),
              ),
            );
          }
        },
      )
      ..loadRequest(Uri.parse('http://192.168.0.106:5000'));

    _controller = controller;
  }

  Future<List<String>> _pickFile(FileSelectorParams params) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return [];
    return [File(result.files.single.path!).uri.toString()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoSort AI Scanner'),
        backgroundColor: Colors.green,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
