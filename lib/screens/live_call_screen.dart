import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_chat_service.dart';
import '../utils/image_utils.dart';
import '../services/screen_share_channel.dart';
import '../theme/tokens.dart';

enum CallPhase { connecting, listening, thinking, speaking, muted }

class LiveCallScreen extends StatefulWidget {
  final AiChatService aiService;
  const LiveCallScreen({super.key, required this.aiService});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  CameraController? _camera;
  Timer? _frameTimer;
  String? _latestFrameBase64;

  CallPhase _phase = CallPhase.connecting;
  bool _isMuted = false;
  bool _isVideoOn = false;
  bool _isScreenSharing = false;
  bool _active = true;
  String _caption = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _tts.setQueueMode(1);
    _tts.setCompletionHandler(() {
      if (_active && !_isMuted) _listenTurn();
    });

    final available = await _speech.initialize(
      onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
    );

    if (!available) {
      final status = await Permission.microphone.status;
      setState(() => _caption = status.isPermanentlyDenied
          ? 'Microphone access denied — enable it in Settings.'
          : 'Microphone permission needed for a live call.');
      return;
    }
    _listenTurn();
  }

  Future<void> _listenTurn() async {
    if (!_active || _isMuted) return;
    setState(() => _phase = CallPhase.listening);
    await _speech.listen(
      onResult: (r) {
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          _handleUtterance(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _handleUtterance(String text) async {
    if (!_active) return;
    await _speech.stop();
    setState(() {
      _phase = CallPhase.thinking;
      _caption = text;
    });

    try {
      final response = await widget.aiService.sendMessage(
        userMessage: text,
        imageBase64: (_isVideoOn || _isScreenSharing) ? _latestFrameBase64 : null,
      );
      if (!mounted || !_active) return;
      setState(() {
        _phase = CallPhase.speaking;
        _caption = response;
      });
      await _tts.speak(response);
    } catch (_) {
      if (!mounted) return;
      setState(() => _caption = "Couldn't reach the AI — listening again.");
      _listenTurn();
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _speech.stop();
      setState(() => _phase = CallPhase.muted);
    } else {
      _listenTurn();
    }
  }

  Future<void> _toggleVideo() async {
    if (_isVideoOn) {
      _frameTimer?.cancel();
      await _camera?.dispose();
      setState(() { _camera = null; _isVideoOn = false; });
      return;
    }
    if (!(await Permission.camera.request()).isGranted) return;

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(front, ResolutionPreset.low, enableAudio: false);
    await controller.initialize();

    _frameTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!controller.value.isInitialized) return;
      final file = await controller.takePicture();
      _latestFrameBase64 = await ImageUtils.fileToBase64DataUri(File(file.path));
    });

    setState(() {
      _camera = controller;
      _isVideoOn = true;
      if (_isScreenSharing) _isScreenSharing = false;
    });
  }

  Future<void> _toggleScreenShare() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen share is Android-only for now.')),
      );
      return;
    }
    if (_isScreenSharing) {
      await ScreenShareChannel.stop();
      setState(() => _isScreenSharing = false);
      return;
    }
    final granted = await ScreenShareChannel.start();
    if (!granted) return;

    ScreenShareChannel.frames.listen((frame) => _latestFrameBase64 = frame);
    setState(() {
      _isScreenSharing = true;
      if (_isVideoOn) _toggleVideo();
    });
  }

  Future<void> _endCall() async {
    _active = false;
    _frameTimer?.cancel();
    await _speech.stop();
    await _tts.stop();
    await _camera?.dispose();
    if (_isScreenSharing) await ScreenShareChannel.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _active = false;
    _frameTimer?.cancel();
    _speech.stop();
    _tts.stop();
    _camera?.dispose();
    super.dispose();
  }

  String get _statusLabel => switch (_phase) {
    CallPhase.connecting => 'Connecting…',
    CallPhase.listening => 'Listening…',
    CallPhase.thinking => 'Thinking…',
    CallPhase.speaking => 'Speaking…',
    CallPhase.muted => 'Muted',
  };

  @override
  Widget build(BuildContext context) {
    final active = _phase == CallPhase.listening || _phase == CallPhase.speaking;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 140 : 120,
              height: active ? 140 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _phase == CallPhase.speaking
                      ? [AppColors.accentCyan, AppColors.accentViolet]
                      : [AppColors.accentSuccess, AppColors.accentCyan],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(_statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_caption, textAlign: TextAlign.center, maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const Spacer(),
            if (_isVideoOn && _camera != null)
              Container(
                width: 100, height: 140,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24)),
                clipBehavior: Clip.hardEdge,
                child: CameraPreview(_camera!),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _callBtn(_isMuted ? Icons.mic_off : Icons.mic, _isMuted, _toggleMute),
                const SizedBox(width: 20),
                _callBtn(_isVideoOn ? Icons.videocam : Icons.videocam_off, _isVideoOn, _toggleVideo),
                const SizedBox(width: 20),
                _callBtn(_isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                    _isScreenSharing, _toggleScreenShare),
                const SizedBox(width: 20),
                _callBtn(Icons.call_end, true, _endCall, color: Colors.red),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _callBtn(IconData icon, bool active, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: color ?? (active ? Colors.white : Colors.white24),
        child: Icon(icon, color: color != null ? Colors.white : (active ? Colors.black : Colors.white)),
      ),
    );
  }
}
