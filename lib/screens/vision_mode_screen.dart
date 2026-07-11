import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../theme/nova_theme.dart';
import '../services/ai_chat_service.dart';
import '../utils/image_utils.dart';

class VisionModeScreen extends StatefulWidget {
  const VisionModeScreen({super.key});

  @override
  State<VisionModeScreen> createState() => _VisionModeScreenState();
}

class _VisionModeScreenState extends State<VisionModeScreen> {
  CameraController? _camera;
  Timer? _timer;
  String _aiDescription = 'Point your camera at something...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _camera = CameraController(back, ResolutionPreset.medium, enableAudio: false);
    await _camera!.initialize();
    if (!mounted) return;
    setState(() {});

    // Analyze every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _analyzeFrame());
  }

  Future<void> _analyzeFrame() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    try {
      final file = await _camera!.takePicture();
      final base64 = await ImageUtils.fileToBase64DataUri(File(file.path));
      final aiService = context.read<AiChatService>();
      final response = await aiService.sendMessage(
        userMessage: 'Describe what you see in this image briefly (1-2 sentences).',
        imageBase64: base64,
        modelOverride: 'google/gemma-4-26b-a4b',
      );
      if (mounted && !response.startsWith('❌')) {
        setState(() => _aiDescription = response);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          Positioned.fill(child: CameraPreview(_camera!)),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Vision Mode',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),

          // AI description overlay
          Positioned(
            bottom: 120, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_aiDescription,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(Icons.refresh, () => _analyzeFrame()),
                _controlButton(Icons.camera, () {}),
                _controlButton(Icons.mic_off, () {}),
                _endCallButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _endCallButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 30),
      ),
    );
  }
}
