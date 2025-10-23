import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../web_ocr.dart' show ocrFromDataUrl;
import '../widgets/buttons.dart';
import 'result_screen.dart';

class ScanWebCameraScreen extends StatefulWidget {
  const ScanWebCameraScreen({super.key});

  @override
  State<ScanWebCameraScreen> createState() => _ScanWebCameraScreenState();
}

class _ScanWebCameraScreenState extends State<ScanWebCameraScreen> {
  List<CameraDescription> _cameras = [];
  int _camIndex = 0;
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(
          () => _error =
              'Tidak ada kamera terdeteksi. Izinkan akses kamera pada situs ini.',
        );
        return;
      }

      // coba kamera belakang; kalau ada nama mengandung "nemesis", pilih itu
      for (int i = 0; i < _cameras.length; i++) {
        final name = (_cameras[i].name ?? '').toLowerCase();
        if (name.contains('nemesis') ||
            _cameras[i].lensDirection == CameraLensDirection.back) {
          _camIndex = i;
          break;
        }
      }
      await _openCamera(_cameras[_camIndex]);
    } catch (e) {
      setState(() => _error = 'Gagal mengakses kamera: $e');
    }
  }

  Future<void> _openCamera(CameraDescription cam) async {
    await _controller?.dispose();
    _controller = CameraController(
      cam,
      ResolutionPreset.low, // lebih stabil di web
      enableAudio: false,
    );
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  Future<void> _switchTo(int index) async {
    _camIndex = index;
    await _openCamera(_cameras[_camIndex]);
  }

  Future<void> _captureAndOcr() async {
    final c = _controller;
    if (c == null) return;
    try {
      await _initFuture;
      final xfile = await c.takePicture();
      final bytes = await xfile.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Memproses OCR (Web)…')));

      final text = await ocrFromDataUrl(dataUrl, lang: 'eng'); // atau 'ind'
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: text)),
      );
    } on CameraException catch (_) {
      // fallback ke picker kamera sistem bila takePicture bermasalah
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
      );
      if (x == null || !mounted) return;
      final dataUrl =
          'data:image/jpeg;base64,${base64Encode(await x.readAsBytes())}';
      final text = await ocrFromDataUrl(dataUrl, lang: 'eng');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: text)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kamera')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera'),
        actions: [
          if (_cameras.isNotEmpty)
            DropdownButton<int>(
              value: _camIndex,
              underline: const SizedBox(),
              onChanged: (v) => v == null ? null : _switchTo(v),
              items: [
                for (int i = 0; i < _cameras.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      (_cameras[i].name ?? 'Camera ${i + 1}'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _initFuture,
              builder: (_, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: CameraPreview(c),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: pillButtonStyle(context),
              onPressed: _captureAndOcr,
              icon: const Icon(Icons.camera),
              label: const Text('Ambil Foto & OCR'),
            ),
          ),
        ],
      ),
    );
  }
}
