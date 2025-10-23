import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../web_ocr.dart' show ocrFromDataUrl;
import '../widgets/buttons.dart';
import 'result_screen.dart';
import 'scan_web_camera.dart'; // layar kamera live (web)

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // === Mobile (Android/iOS) ===
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initCameraMobile();
  }

  Future<void> _initCameraMobile() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      final controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: (defaultTargetPlatform == TargetPlatform.iOS)
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      _controller = controller;
      _initializeControllerFuture = controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menginisialisasi kamera: $e')),
      );
    }
  }

  Future<String> _ocrMobileFromPath(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> _takePictureMobile() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await _initializeControllerFuture;
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Memproses OCR...')));

      final xfile = await controller.takePicture();
      final text = await _ocrMobileFromPath(xfile.path);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: text)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat foto/OCR: $e')));
    }
  }

  // === Web (Tesseract.js) — kamera live & galeri ===
  final _picker = ImagePicker();

  Future<void> _pickFromGalleryWeb() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Memproses OCR (Web)...')));

      final text = await ocrFromDataUrl(dataUrl, lang: 'eng'); // atau 'ind'
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: text)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error OCR Web: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // === WEB ===
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('OCR')), // tanpa "(Web)"
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: pillButtonStyle(context), // << sama seperti menu utama
                icon: const Icon(Icons.camera_alt),
                label: const Text('Pilih menggunakan Kamera'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanWebCameraScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: pillButtonStyle(context), // << sama persis
                icon: const Icon(Icons.photo_library),
                label: const Text('Pilih dari Folder / Galeri Foto'),
                onPressed: _pickFromGalleryWeb,
              ),
            ],
          ),
        ),
      );
    }

    // === ANDROID/iOS ===
    final controller = _controller;
    if (controller == null || controller.value.isInitialized == false) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kamera OCR (Mobile)')),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: pillButtonStyle(context),
              onPressed: _takePictureMobile,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto & Scan'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
