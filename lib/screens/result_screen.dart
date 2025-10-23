import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String ocrText;

  const ResultScreen({super.key, required this.ocrText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final FlutterTts _tts;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
    _bindHandlers();
  }

  Future<void> _initTts() async {
    // Setelan dasar TTS (Bahasa Indonesia)
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(1.0); // 0.0 - 1.0
    await _tts.setPitch(1.0); // 0.5 - 2.0
    await _tts.setVolume(1.0); // 0.0 - 1.0
  }

  void _bindHandlers() {
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
      // Tidak menampilkan detail error ke pengguna sesuai gaya Soal 2
    });
  }

  Future<void> _speakAll() async {
    final text = widget.ocrText.trim();
    if (text.isEmpty) return;
    await _tts.stop(); // cegah overlap
    await _tts.speak(text); // bacakan seluruh hasil OCR
  }

  Future<void> _stop() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String ocrText = widget.ocrText; // tampilkan newline apa adanya

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            ocrText.isEmpty ? '(Tidak ada teks)' : ocrText,
            textAlign: TextAlign.left,
          ),
        ),
      ),
      // Dua FAB: TTS (play/stop) + Home
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_tts',
            onPressed: _isSpeaking ? _stop : _speakAll,
            tooltip: _isSpeaking ? 'Hentikan bacaan' : 'Bacakan teks',
            child: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_home',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Kembali ke Beranda',
            child: const Icon(Icons.home),
          ),
        ],
      ),
    );
  }
}
