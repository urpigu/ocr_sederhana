// lib/web_ocr.dart
import 'package:js/js.dart';
import 'package:js/js_util.dart' as jsutil;

@JS('tesseractOcr')
external Object _tesseractOcr(String dataUrl, String lang);

Future<String> ocrFromDataUrl(String dataUrl, {String lang = 'eng'}) async {
  final res = await jsutil.promiseToFuture<String>(
    _tesseractOcr(dataUrl, lang),
  );
  return res;
}
