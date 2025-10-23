import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String ocrText;
  const ResultScreen({super.key, required this.ocrText});

  @override
  Widget build(BuildContext context) {
    final normalized = ocrText.trim().isEmpty
        ? 'Tidak ada teks ditemukan.'
        : ocrText.replaceAll('\n', ' ');
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            normalized,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
