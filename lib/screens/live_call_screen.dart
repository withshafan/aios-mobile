import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_chat_service.dart';
import '../services/universal_ai_service.dart';
import '../services/voice_service.dart';
import '../utils/image_utils.dart';
import '../services/screen_share_channel.dart';
import '../theme/tokens.dart';

enum CallPhase { connecting, listening, thinking, speaking, muted, permissionDenied, unsupported }

class LiveCallScreen extends StatefulWidget {
  final UniversalAiService aiService;
  const LiveCallScreen({super.key, required this.aiService});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with TickerProviderStateMixin {
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
  String _debugInfo = '';

  late final AnimationController _pulseController;
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
    _start();
  }

  @override
  void dispose() {
    _active = false;
    _frameTimer?.cancel();
    _speech.stop();
    _tts.stop();
    _camera?.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    if (_isScreenSharing) ScreenShareChannel.stop();
    super.dispose();
  }

  Future<void> _start() async {
    await _tts.setQueueMode(1);
    _tts.setCompletionHandler(() {
      if (_active && !_isMuted) _listenTurn();
    });

    // Check microphone permission first
    final micStatus = await Permission.microphone.status;
    debugPrint('🎤 Mic permission status: $micStatus');

    if (!micStatus.isGranted) {
      final requested = await Permission.microphone.request();
      debugPrint('🎤 Mic permission requested: $requested');
      if (!requested.isGranted) {
        setState(() => _phase = CallPhase.permissionDenied);
        return;
      }
    }

    final available = await _speech.initialize(
      onError: (e) {
        debugPrint('🎤 STT error: ${e.errorMsg}');
        setState(() => _debugInfo = 'STT error: ${e.errorMsg}');
      },
      onStatus: (status) {
        debugPrint('🎤 STT status: $status');
        if (status == 'listening') {
          setState(() => _debugInfo = 'Listening...');
        }
      },
    );

    debugPrint('🎤 SpeechToText available: $available');
    if (!available) {
      setState(() => _phase = CallPhase.unsupported);
      return;
    }
    _listenTurn();
  }

  Future<void> _listenTurn() async {
    if (!_active || _isMuted) return;
    setState(() => _phase = CallPhase.listening);

    debugPrint('🎤 Starting to listen...');
    await _speech.listen(
      onResult: (r) {
        debugPrint('🎤 Result: ${r.recognizedWords} (final: ${r.finalResult})');
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          _handleUtterance(r.recognizedWords);
        }
        if (!r.finalResult) {
          setState(() => _caption = r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.search,
      ),
    );
  }

  bool _apiInFlight = false;

  Future<void> _handleUtterance(String text) async {
    if (!_active || _apiInFlight) return;
    _apiInFlight = true;
    await _speech.stop();
    setState(() { _phase = CallPhase.thinking; _caption = text; });

    try {
      final response = await widget.aiService.sendMessage(
        userMessage: text,
        imageBase64: (_isVideoOn || _isScreenSharing) ? _latestFrameBase64 : null,
      );

      // Check if response is an error
      if (response.startsWith('❌')) {
        if (!mounted || !_active) return;
        setState(() {
          _phase = CallPhase.muted;
          _caption = response;
        });
        return;
      }

      if (!mounted || !_active) return;
      setState(() { _phase = CallPhase.speaking; _caption = response; });

      final sentences = response.split(RegExp(r'(?<=[.!?])\s+'));
      for (final sentence in sentences) {
        if (!_active) return;
        await _tts.speak(sentence);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _caption = "Couldn't reach the AI — listening again.";
        _phase = CallPhase.muted;
      });
    } finally {
      _apiInFlight = false;
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
    if (!(await Permission.camera.request()).isGranted) {
      setState(() => _caption = 'Camera permission denied');
      return;
    }
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();

      _frameTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (!controller.value.isInitialized) return;
        final file = await controller.takePicture();
        _latestFrameBase64 = await ImageUtils.fileToBase64DataUri(File(file.path));
      });

      setState(() {
        _camera = controller;
        _isVideoOn = true;
        if (_isScreenSharing) _isScreenSharing = false;
      });
    } catch (e) {
      setState(() => _caption = 'Camera error: $e');
    }
  }

  Future<void> _toggleScreenShare() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen share is Android-only')),
      );
      return;
    }
    if (_isScreenSharing) {
      await ScreenShareChannel.stop();
      setState(() => _isScreenSharing = false);
      return;
    }
    try {
      final granted = await ScreenShareChannel.start();
      if (!granted) {
        setState(() => _caption = 'Screen share permission denied');
        return;
      }
      ScreenShareChannel.frames.listen(
        (frame) => _latestFrameBase64 = frame,
        onError: (e) => debugPrint('Screen share error: $e'),
      );
      setState(() {
        _isScreenSharing = true;
        if (_isVideoOn) _toggleVideo();
      });
    } catch (e) {
      setState(() => _caption = 'Screen share error: $e');
    }
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

  String get _statusLabel => switch (_phase) {
    CallPhase.connecting => 'Connecting…',
    CallPhase.listening => 'Listening…',
    CallPhase.thinking => 'Thinking…',
    CallPhase.speaking => 'Speaking…',
    CallPhase.muted => 'Muted',
    CallPhase.permissionDenied => 'Mic permission denied',
    CallPhase.unsupported => 'Voice not supported on this device',
  };

  @override
  Widget build(BuildContext context) {
    final isActive = _phase == CallPhase.listening || _phase == CallPhase.speaking;
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Text(_statusLabel,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const Spacer(),
                _buildCenterPiece(isActive),
                const Spacer(),
                if (_caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_caption,
                        textAlign: TextAlign.center, maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                  ),
                // Show debug info during development
                if (_debugInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_debugInfo,
                        style: TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                  ),
                const Spacer(),
                _buildControls(),
                const SizedBox(height: 30),
              ],
            ),
            if (_isVideoOn && _camera != null)
              Positioned(
                top: 60, right: 20,
                child: Container(
                  width: 120, height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentViolet, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CameraPreview(_camera!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPiece(bool isActive) {
    if (_isVideoOn && _camera != null) {
      return Container(
        width: 260, height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentViolet.withOpacity(0.5), width: 2),
        ),
        clipBehavior: Clip.hardEdge,
        child: CameraPreview(_camera!),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _ringController]),
      builder: (context, _) {
        final pulseScale = 1.0 + (_pulseController.value * 0.15);
        return SizedBox(
          width: 200, height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_ringController.value * 0.3),
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentViolet.withOpacity(0.3 - _ringController.value * 0.2),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + (_ringController.value * 0.15),
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.accentViolet.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isActive
                          ? [AppColors.accentCyan, AppColors.accentViolet]
                          : [AppColors.textDisabled, AppColors.textSecondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentViolet.withOpacity(0.4),
                        blurRadius: 30, spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? AppColors.accentCritical : AppColors.surfaceOverlay,
              onTap: _toggleMute, label: _isMuted ? 'Unmute' : 'Mute'),
          _circleButton(icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              color: _isVideoOn ? AppColors.accentViolet : AppColors.surfaceOverlay,
              onTap: _toggleVideo, label: 'Video'),
          _circleButton(icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              color: _isScreenSharing ? AppColors.accentSuccess : AppColors.surfaceOverlay,
              onTap: _toggleScreenShare, label: 'Share'),
          _circleButton(icon: Icons.call_end,
              color: AppColors.accentCritical, onTap: _endCall, label: 'End'),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required Color color,
      required VoidCallback onTap, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
