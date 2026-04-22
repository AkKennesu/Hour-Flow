import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../utils/time_card_parser.dart';

class ScanService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Takes an image file and returns the parsed list of [ScannedTimeLog].
  Future<List<ScannedTimeLog>> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    return TimeCardParser.parse(recognizedText);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
