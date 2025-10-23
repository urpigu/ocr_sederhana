import 'package:flutter/material.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String ocrText;

  const ResultScreen({super.key, required this.ocrText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    final String ocrText = widget.ocrText;

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
      // FAB Home -> kembali ke Home dan mengosongkan stack
      floatingActionButton: FloatingActionButton(
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
    );
  }
}
