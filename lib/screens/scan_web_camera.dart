import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../web_ocr.dart' show ocrFromDataUrl;
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

  String _camLabel(CameraDescription c, int i) {
    // Gunakan properti name jika ada; fallback label generik
    final name = c.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Camera ${i + 1} (${c.lensDirection.name})';
  }

  Future<void> _init() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(
          () => _error =
              'Tidak ada kamera terdeteksi. Izinkan kamera (ikon gembok → Camera: Allow).',
        );
        return;
      }

      // Auto-pilih kamera yang mengandung "nemesis" (eksternal), jika ada
      for (int i = 0; i < _cameras.length; i++) {
        final n = (_cameras[i].name ?? '').toLowerCase();
        if (n.contains('nemesis')) {
          _camIndex = i;
          break;
        }
      }

      await _openCamera(_cameras[_camIndex]);
    } catch (e) {
      setState(
        () => _error =
            'Gagal mengakses kamera. Pastikan browser mengizinkan (ikon gembok → Camera: Allow). Detail: $e',
      );
    }
  }

  Future<void> _openCamera(CameraDescription cam) async {
    await _controller?.dispose();
    _controller = CameraController(
      cam,
      // resolusi rendah → lebih stabil di web
      ResolutionPreset.low,
      enableAudio: false,
    );
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  Future<void> _switchTo(int index) async {
    _camIndex = index;
    await _openCamera(_cameras[_camIndex]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndOcr() async {
    final c = _controller;
    if (c == null) return;
    try {
      await _initFuture;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengambil foto…')));

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
    } on CameraException catch (e) {
      // Fallback jika takePicture error (cameraNotReadable)
      debugPrint('CameraException: ${e.code} – ${e.description}');
      await _fallbackPickFromCamera();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto/OCR: $e')));
    }
  }

  Future<void> _fallbackPickFromCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memproses OCR (Fallback)…')),
      );

      final text = await ocrFromDataUrl(dataUrl, lang: 'eng');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: text)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fallback gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kamera (Web)')),
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
        title: const Text('Kamera (Web)'),
        actions: [
          if (_cameras.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<int>(
                value: _camIndex,
                underline: const SizedBox(),
                onChanged: (v) => v == null ? null : _switchTo(v),
                items: [
                  for (int i = 0; i < _cameras.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        _camLabel(_cameras[i], i),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _initFuture,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _captureAndOcr,
                  icon: const Icon(Icons.camera),
                  label: const Text('Ambil Foto & OCR'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _fallbackPickFromCamera,
                  icon: const Icon(Icons.photo_camera_back),
                  label: const Text('Fallback (Picker)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
