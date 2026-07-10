import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  // Wake word state
  bool _wakeWordActive = false;
  bool get wakeWordActive => _wakeWordActive;

  // Callback when wake word is detected
  Function()? onWakeWordDetected;

  VoiceService() {
    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.5);
  }

  Future<bool> initStt() async => await _stt.initialize();

  /// Normal single-shot listen (for mic button)
  Future<String?> listen({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isListening) return null;
    _isListening = true;
    notifyListeners();

    String? recognizedText;
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          recognizedText = result.recognizedWords;
        }
      },
      listenFor: timeout,
    );
    await Future.delayed(timeout);
    _stt.stop();
    _isListening = false;
    notifyListeners();
    return recognizedText;
  }

  /// Continuous listening for wake word
  Future<void> startWakeWordListening() async {
    if (_wakeWordActive) return;
    _wakeWordActive = true;
    notifyListeners();

    // Use continuous listening with partial results
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.toLowerCase().contains('hey aios')) {
          // Wake word detected! Stop listening, call callback
          _stt.stop();
          _wakeWordActive = false;
          notifyListeners();
          onWakeWordDetected?.call();
        }
      },
      listenFor: const Duration(minutes: 30), // keep listening until stopped
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopWakeWordListening() {
    if (_wakeWordActive) {
      _stt.cancel();
      _wakeWordActive = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    stopWakeWordListening();
    super.dispose();
  }
}
