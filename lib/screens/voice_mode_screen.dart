import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/nova_theme.dart';
import '../widgets/animated_orb.dart';

class VoiceModeScreen extends StatefulWidget {
  final Function(String) onResult;

  const VoiceModeScreen({super.key, required this.onResult});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  String _caption = '';
  late final AnimationController _equalizerController;
  final List<double> _bars = List.generate(12, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    _initSpeech();
  }

  @override
  void dispose() {
    _equalizerController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    setState(() => _listening = true);
    _speech.listen(
      onResult: (result) {
        setState(() => _caption = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speech.stop();
          widget.onResult(result.recognizedWords);
          Navigator.pop(context);
        }
      },
      listenFor: const Duration(seconds: 30),
    );
    // Simulate bar animation
    _equalizerController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? NovaColors.darkBg : NovaColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Central orb
            AnimatedOrb(size: 140, isActive: _listening),
            const SizedBox(height: 40),
            // Equalizer bars
            SizedBox(
              height: 80,
              child: AnimatedBuilder(
                animation: _equalizerController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(12, (i) {
                      final height = _listening
                          ? 10.0 + (sin(_equalizerController.value * 10 + i) * 30).abs()
                          : 5.0;
                      return Container(
                        width: 4,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: NovaColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _caption.isEmpty ? 'Simply start speaking…' : _caption,
              style: TextStyle(
                color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_off,
                      color: _listening ? NovaColors.accent : NovaColors.error,
                    ),
                    onPressed: () {
                      if (_listening) {
                        _speech.stop();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
