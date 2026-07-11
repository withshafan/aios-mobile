// lib/screens/voice_input_overlay.dart (final)
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/tokens.dart';

enum VoiceOverlayStatus {
  initializing,
  listening,
  processing,
  permissionDenied,
  permissionPermanentlyDenied,
  unsupported,
  error,
}

class VoiceInputOverlay extends StatefulWidget {
  const VoiceInputOverlay({
    super.key,
    required this.onResult,
    this.onClose,
    this.ttsInstance,
  });

  final ValueChanged<String> onResult;
  final VoidCallback? onClose;
  final FlutterTts? ttsInstance;

  @override
  State<VoiceInputOverlay> createState() => _VoiceInputOverlayState();
}

class _VoiceInputOverlayState extends State<VoiceInputOverlay>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  VoiceOverlayStatus _status = VoiceOverlayStatus.initializing;
  String _caption = '';
  String _errorMessage = '';
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 1. Stop any TTS that might be holding audio focus
    if (widget.ttsInstance != null) {
      await widget.ttsInstance!.stop();
    }

    // 2. Check current permission status (read-only, never request)
    final micStatus = await Permission.microphone.status;
    if (micStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _status = VoiceOverlayStatus.permissionPermanentlyDenied);
      }
      return;
    }

    // 3. Let SpeechToText handle the request if needed
    bool available;
    try {
      available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
      );
    } catch (_) {
      available = false;
    }

    if (!mounted) return;

    if (!available) {
      // Check if permission was denied after initialization attempt
      final statusAfter = await Permission.microphone.status;
      if (statusAfter.isDenied) {
        setState(() => _status = VoiceOverlayStatus.permissionDenied);
      } else {
        setState(() => _status = VoiceOverlayStatus.unsupported);
      }
      return;
    }

    _startListening();
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() => _status = VoiceOverlayStatus.listening);
      return;
    }
    if (status == 'notListening' || status == 'done') {
      if (_status != VoiceOverlayStatus.listening) return;
      if (_caption.trim().isNotEmpty) {
        _finish(_caption);
      } else {
        setState(() {
          _status = VoiceOverlayStatus.error;
          _errorMessage = "I didn't catch that. Try again?";
        });
      }
    }
  }

  void _handleError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _status = VoiceOverlayStatus.error;
      _errorMessage = _mapErrorMessage(error.errorMsg);
    });
  }

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'error_no_match':
        return "I didn't catch that. Try again?";
      case 'error_speech_timeout':
        return 'No speech detected. Tap to try again.';
      case 'error_audio_error':
      case 'error_audio':
        return 'Microphone is busy or unavailable right now.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Network issue — try again in a moment.';
      case 'error_permission':
        return 'Microphone permission was revoked.';
      default:
        return 'Voice recognition ran into a problem ($code).';
    }
  }

  void _startListening() {
    setState(() {
      _status = VoiceOverlayStatus.listening;
      _caption = '';
      _errorMessage = '';
    });
    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() => _caption = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _finish(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  void _retry() {
    setState(() => _status = VoiceOverlayStatus.initializing);
    _bootstrap();
  }

  void _finish(String text) {
    _speech.stop();
    if (mounted) setState(() => _status = VoiceOverlayStatus.processing);
    widget.onResult(text.trim());
    widget.onClose?.call();
  }

  void _cancel() {
    _speech.cancel();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCanvas.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: _cancel,
              ),
            ),
            Expanded(child: Center(child: _buildBody())),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildActionRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case VoiceOverlayStatus.initializing:
        return SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentViolet),
          ),
        );
      case VoiceOverlayStatus.permissionDenied:
        return _MessageView(
          icon: Icons.mic_off,
          title: 'Microphone permission needed',
          message: 'AURA needs microphone access to hear you. Tap below to allow it.',
          actionLabel: 'Try again',
          onAction: _retry,
        );
      case VoiceOverlayStatus.permissionPermanentlyDenied:
        return _MessageView(
          icon: Icons.settings,
          title: 'Microphone access is blocked',
          message: 'You previously denied microphone access. Enable it in system settings.',
          actionLabel: 'Open settings',
          onAction: () async => await openAppSettings(),
        );
      case VoiceOverlayStatus.unsupported:
        return _MessageView(
          icon: Icons.mic_off,
          title: "Voice input isn't available here",
          message: "This device doesn't support on-device speech recognition. You can still type your message.",
          actionLabel: 'Use keyboard instead',
          onAction: _cancel,
        );
      case VoiceOverlayStatus.error:
        return _MessageView(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          message: _errorMessage,
          actionLabel: 'Try again',
          onAction: _retry,
        );
      case VoiceOverlayStatus.processing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentViolet),
              ),
            ),
            const SizedBox(height: 16),
            Text('Thinking…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        );
      case VoiceOverlayStatus.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingOrb(controller: _pulseController),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _caption.isEmpty ? 'Listening…' : _caption,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionRow() {
    if (_status != VoiceOverlayStatus.listening) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 36,
          icon: Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: _cancel,
        ),
        const SizedBox(width: 40),
        IconButton(
          iconSize: 48,
          icon: Icon(Icons.check_circle, color: AppColors.accentSuccess),
          onPressed: () {
            if (_caption.trim().isNotEmpty) {
              _finish(_caption);
            } else {
              _cancel();
            }
          },
        ),
      ],
    );
  }
}

class _PulsingOrb extends StatelessWidget {
  const _PulsingOrb({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1.0 + (controller.value * 0.25);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentViolet.withOpacity(0.9),
                  AppColors.accentViolet.withOpacity(0.1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentViolet,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
