import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/nova_theme.dart';
import '../widgets/animated_orb.dart';
import '../widgets/sources_card.dart';
import '../services/memory_service.dart';
import '../services/file_extraction_service.dart';
import '../services/ai_chat_service.dart';          // ← FIXED
import '../utils/image_utils.dart';
import 'voice_mode_screen.dart';
import 'vision_mode_screen.dart';
import 'live_call_screen.dart';

class NovaChatScreen extends StatefulWidget {
  final AiChatService aiService;                    // ← FIXED

  const NovaChatScreen({super.key, required this.aiService});

  @override
  State<NovaChatScreen> createState() => _NovaChatScreenState();
}

class _NovaChatScreenState extends State<NovaChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FileExtractionService _extractionService = FileExtractionService();
  final FlutterTts _tts = FlutterTts();

  final List<_ChatMessage> _messages = [];
  final List<_QueuedRequest> _queue = [];
  bool _isProcessingQueue = false;
  int _idCounter = 0;

  File? _attachedFile;
  String? _attachedFileName;
  bool _isImageFile = false;

  bool _speakerOn = false;

  final List<_QuickAction> _quickActions = [
    _QuickAction('Ask Anything', Icons.auto_awesome),
    _QuickAction('Create Image', Icons.image),
    _QuickAction('Analyze', Icons.analytics),
    _QuickAction('Brainstorm', Icons.lightbulb),
    _QuickAction('Code', Icons.code),
  ];

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    _tts.setQueueMode(1);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  String _selectModel(String userText, {bool hasImage = false}) {
    // Use only FREE models – no credits needed
    if (hasImage) return 'meta-llama/llama-3.2-11b-vision-instruct:free';
    return 'meta-llama/llama-3.2-3b-instruct:free';
  }

  void _sendMessage({String? text}) async {
    final userText = text ?? _controller.text.trim();
    if (userText.isEmpty && _attachedFile == null) return;
    _controller.clear();

    final id = _newId();
    final imageFile = _attachedFile;
    final isImage = _isImageFile;
    final fileName = _attachedFileName;

    setState(() {
      _messages.add(_ChatMessage(
        id: id,
        text: userText,
        isUser: true,
        imageFile: imageFile,
        imageFileName: fileName,
        status: _isProcessingQueue ? 'Queued' : 'Sending',
      ));
      _attachedFile = null;
      _attachedFileName = null;
      _isImageFile = false;
    });

    _queue.add(_QueuedRequest(id: id, text: userText, imageFile: imageFile, isImage: isImage));
    if (!_isProcessingQueue) _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_queue.isNotEmpty) {
      final req = _queue.removeAt(0);
      _setStatus(req.id, 'Thinking…');

      final thinkingId = '${req.id}_thinking';
      setState(() => _messages.add(_ChatMessage(id: thinkingId, text: '···', isUser: false, status: 'Thinking')));

      try {
        String? imageDataUri;
        if (req.imageFile != null && req.isImage) {
          imageDataUri = await ImageUtils.fileToBase64DataUri(req.imageFile!);
        } else if (req.imageFile != null) {
          final extracted = await _extractionService.extract(req.imageFile!);
          if (extracted != null) {
            req.text = '${req.text}\n\nAttached file content:\n"""\n$extracted\n"""';
          }
        }

        final modelId = _selectModel(req.text, hasImage: imageDataUri != null);

        final keyToUse = dotenv.env['OPENROUTER_API_KEY'] ?? '';

        // ✅ Call AiChatService, get a String back
        final replyText = await widget.aiService.sendMessage(
          userMessage: req.text.isEmpty ? 'Hello!' : req.text,
          imageBase64: imageDataUri,
          modelOverride: modelId,
          apiKeyOverride: keyToUse,
        );

        final isError = replyText.startsWith('❌');

        setState(() {
          _messages.removeWhere((m) => m.id == thinkingId);
          _messages.add(_ChatMessage(
            id: isError ? '${req.id}_err' : '${req.id}_ans',
            text: replyText,
            isUser: false,
            status: isError ? 'Error' : 'Sent',
          ));
          _setStatus(req.id, 'Sent');
        });

        if (_speakerOn && !isError) {
          _tts.speak(replyText);
        }
      } catch (_) {
        setState(() {
          _messages.removeWhere((m) => m.id == thinkingId);
          _messages.add(_ChatMessage(
            id: '${req.id}_err',
            text: "Couldn't answer – tap to retry.",
            isUser: false,
            status: 'Error',
          ));
          _setStatus(req.id, 'Error');
        });
      }
    }
    _isProcessingQueue = false;
  }

  void _setStatus(String id, String status) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i != -1) {
      _messages[i].status = status;
      setState(() {});
    }
  }

  // ── Attachments ──
  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      final f = File(result.files.first.path!);
      final ext = result.files.first.name.split('.').last.toLowerCase();
      final imageExts = ['jpg', 'jpeg', 'png', 'webp'];
      setState(() {
        _attachedFile = f;
        _attachedFileName = result.files.first.name;
        _isImageFile = imageExts.contains(ext);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _attachedFile = File(picked.path);
        _attachedFileName = picked.name;
        _isImageFile = true;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
      _isImageFile = false;
    });
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? NovaColors.darkBg : NovaColors.lightBg;
    final textColor = isDark ? NovaColors.darkText : NovaColors.lightText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _messages.isEmpty && _queue.isEmpty
              ? Expanded(child: _buildEmptyState(isDark, textColor))
              : Expanded(child: _buildMessageList(isDark)),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? NovaColors.darkBg : NovaColors.lightBg,
      elevation: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          const AnimatedOrb(size: 32, isActive: false),
          const SizedBox(width: 12),
          const Text('AURA', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call, color: NovaColors.accent),
          tooltip: 'Live call',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveCallScreen(aiService: widget.aiService),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(_speakerOn ? Icons.volume_up : Icons.volume_off,
              color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary),
          onPressed: () => setState(() => _speakerOn = !_speakerOn),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const AnimatedOrb(size: 100, isActive: true),
          const SizedBox(height: 32),
          Text('Hi! How can I help you today?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickActions.map((action) {
              return GestureDetector(
                onTap: () {
                  _controller.text = action.label;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: NovaColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon, size: 16, color: NovaColors.accent),
                      const SizedBox(width: 6),
                      Text(action.label, style: TextStyle(color: NovaColors.accent, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildBubble(msg, isDark);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg, bool isDark) {
    if (msg.text == '···') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const AnimatedOrb(size: 28, isActive: true),
            const SizedBox(width: 8),
            Text('Generating…',
                style: TextStyle(color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary)),
          ],
        ),
      );
    }

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? NovaColors.darkSurface : NovaColors.lightSurface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageFileName != null)
                Text('📎 ${msg.imageFileName}',
                    style: TextStyle(fontSize: 12, color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary)),
              Text(msg.text, style: TextStyle(color: isDark ? NovaColors.darkText : NovaColors.lightText)),
              if (msg.status == 'Queued')
                Text('Queued', style: TextStyle(fontSize: 10, color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary)),
            ],
          ),
        ),
      );
    }

    final isError = msg.status == 'Error';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.text,
              style: TextStyle(
                color: isError ? NovaColors.error : (isDark ? NovaColors.darkText : NovaColors.lightText),
                height: 1.5,
              )),
          const SizedBox(height: 8),
          if (!isError && msg.text.length > 50)
            SourcesCard(sources: [
              {'title': 'Web Search'},
              {'title': 'Knowledge Base'},
            ]),
          Row(
            children: [
              _actionBtn(Icons.copy, 'Copy', () {
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
              }),
              const SizedBox(width: 4),
              _actionBtn(Icons.refresh, 'Retry', () {
                final lastUser = _messages.lastWhere((m) => m.isUser, orElse: () => msg);
                _sendMessage(text: lastUser.text);
              }),
              const SizedBox(width: 4),
              _actionBtn(Icons.share, 'Share', () => Share.share(msg.text)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: NovaColors.accent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: NovaColors.accent),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: NovaColors.accent, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? NovaColors.darkBg : NovaColors.lightBg,
        border: Border(top: BorderSide(color: isDark ? NovaColors.darkBorder : NovaColors.lightBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachedFile != null)
            Row(
              children: [
                _isImageFile
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_attachedFile!, width: 60, height: 60, fit: BoxFit.cover))
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? NovaColors.darkSurface : NovaColors.lightSurface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_attachedFileName ?? '', style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _removeAttachment),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary),
                onPressed: _pickAttachment,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: isDark ? NovaColors.darkText : NovaColors.lightText),
                  decoration: InputDecoration(
                    hintText: 'Message Aura...',
                    hintStyle: TextStyle(color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary),
                    filled: true,
                    fillColor: isDark ? NovaColors.darkSurface : NovaColors.lightSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.mic, color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VoiceModeScreen(
                      onResult: (text) => _sendMessage(text: text),
                    ),
                  ));
                },
              ),
              IconButton(
                icon: Icon(Icons.send, color: NovaColors.accent),
                onPressed: () => _sendMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──
class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final File? imageFile;
  final String? imageFileName;
  String status;

  _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.imageFile,
    this.imageFileName,
    this.status = 'Sent',
  });
}

class _QueuedRequest {
  final String id;
  String text;
  final File? imageFile;
  final bool isImage;

  _QueuedRequest({required this.id, required this.text, this.imageFile, this.isImage = false});
}

class _QuickAction {
  final String label;
  final IconData icon;
  const _QuickAction(this.label, this.icon);
}
