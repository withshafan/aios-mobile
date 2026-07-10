import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> initStt() async => await _stt.initialize();

  Future<String?> listen() async {
    if (!_isListening) {
      _isListening = true;
      final result = await _stt.listen(
        onResult: (val) {},
      );
      await Future.delayed(const Duration(seconds: 5)); // simple timeout
      _stt.stop();
      _isListening = false;
      return _stt.lastRecognizedWords.isNotEmpty ? _stt.lastRecognizedWords : null;
    }
    return null;
  }

  Future<void> speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  void stopListening() {
    if (_isListening) {
      _stt.stop();
      _isListening = false;
    }
  }
}
