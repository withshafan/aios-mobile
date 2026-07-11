// ============================================================================
// chat_screen.dart
//
// Self-contained Aura-themed chat screen for an AI assistant app.
//
// Required dependencies (pubspec.yaml):
//   provider: ^6.1.0
//   flutter_animate: ^4.5.0
//   image_picker: ^1.1.0
//   file_picker: ^8.0.0
//   share_plus: ^10.0.0
//   speech_to_text: ^7.0.0
//   flutter_tts: ^4.0.0
//
// Platform setup you'll still need to do outside this file:
//   - iOS Info.plist: NSCameraUsageDescription, NSPhotoLibraryUsageDescription,
//     NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription.
//   - Android AndroidManifest.xml: CAMERA and RECORD_AUDIO permissions.
//
// Usage:
//   ChatScreen(sendMessage: myAiChatService.sendMessage)
//
// Where `myAiChatService.sendMessage` matches the signature:
//   Future<String> Function({required String userMessage,
//                             List<Map<String, String>> history})
// ============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../utils/image_utils.dart';
import '../services/ai_chat_service.dart';
import 'live_call_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_input_overlay.dart';

// ============================================================================
// AURA DESIGN TOKENS
// ============================================================================

class AuraColors {
  AuraColors._();

  static const background = Color(0xFF0A0B10);
  static const surface = Color(0xFF12141C);
  static const surfaceRaised = Color(0xFF181B26);
  static const surfaceOverlay = Color(0xFF1E2230);

  static const violet = Color(0xFF6E5BFF);
  static const cyan = Color(0xFF37D0FF);

  static const textPrimary = Color(0xFFF3F4F8);
  static const textSecondary = Color(0xFFA8ADBC);
  static const textMuted = Color(0xFF6B7080);
  static const danger = Color(0xFFFF7A7A);
  static const divider = Color(0xFF20232E);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [violet, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AuraRadii {
  AuraRadii._();
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

class AuraSpacing {
  AuraSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AuraText {
  AuraText._();

  static const body = TextStyle(
    color: AuraColors.textPrimary,
    fontSize: 15.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const bodySecondary = TextStyle(
    color: AuraColors.textSecondary,
    fontSize: 13.5,
    height: 1.4,
  );

  static const caption = TextStyle(
    color: AuraColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const chip = TextStyle(
    color: AuraColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

// ============================================================================
// MODELS
// ============================================================================

enum MessageRole { user, ai }

enum MessageStatus { queued, sending, sent, error }

enum AttachmentType { image, file }

class ChatAttachment {
  ChatAttachment({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.extractedText,
  });

  final String id;
  final AttachmentType type;
  final String name;
  final String path;
  final int sizeBytes;
  final String? extractedText;

  String get extension => name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.attachments = const [],
    DateTime? timestamp,
    this.status = MessageStatus.sent,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final MessageRole role;
  final String content;
  final List<ChatAttachment> attachments;
  final DateTime timestamp;
  MessageStatus status;
}

// ============================================================================
// DOCUMENT TEXT EXTRACTION
// ============================================================================

/// Pulls readable text out of an attached file so it can be sent to the
/// assistant alongside the user's message.
abstract class DocumentTextExtractor {
  Future<String?> extractText(File file, String extension);
}

/// Reads plain-text formats directly. Binary formats like PDF/DOCX need a
/// dedicated parser package (e.g. syncfusion_flutter_pdf, docx_to_text) —
/// wire one in here when you need it. Rather than pretending to parse bytes
/// it can't actually read, this degrades gracefully: the file still attaches
/// and is still named in the conversation, it just won't have inline text.
class DefaultDocumentTextExtractor implements DocumentTextExtractor {
  static const _plainTextExtensions = {'txt', 'md', 'csv', 'json'};

  @override
  Future<String?> extractText(File file, String extension) async {
    if (!_plainTextExtensions.contains(extension.toLowerCase())) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// EXTERNAL SERVICE CONTRACT
// ============================================================================

/// Matches the signature of an external AiChatService.sendMessage method.
/// Pass a real implementation's method in directly, e.g.:
///   ChatScreen(sendMessage: myAiChatService.sendMessage)
typedef SendMessageFn = Future<String> Function({
  required String userMessage,
  List<Map<String, String>> history,
  String? imageBase64,
});

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required SendMessageFn sendMessage,
    DocumentTextExtractor? textExtractor,
  })  : _sendMessage = sendMessage,
        _textExtractor = textExtractor ?? DefaultDocumentTextExtractor() {
    _initTts();
  }

  final SendMessageFn _sendMessage;
  final DocumentTextExtractor _textExtractor;

  // ── Messages & attachments ──
  final List<ChatMessage> messages = [];
  final List<ChatAttachment> pendingAttachments = [];
  ChatMessage? _lastUserMessage;
  int _idCounter = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  // ── Queue ──
  final Queue<_QueuedRequest> _messageQueue = Queue<_QueuedRequest>();
  bool _isProcessingQueue = false;

  // ── TTS ──
  final FlutterTts _flutterTts = FlutterTts();
  bool _speakerOn = false;
  bool get speakerOn => _speakerOn;

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setQueueMode(1); // QUEUE_ADD
  }

  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    if (!_speakerOn) _flutterTts.stop();
    notifyListeners();
  }

  Future<void> _speakResponse(String text) async {
    if (!_speakerOn || text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  // ── Attachments ──
  void addAttachment(ChatAttachment attachment) {
    pendingAttachments.add(attachment);
    notifyListeners();
  }

  void removeAttachment(String id) {
    pendingAttachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<ChatAttachment> buildAttachmentFromFile(File file, {required AttachmentType type}) async {
    final name = file.uri.pathSegments.last;
    final ext = name.contains('.') ? name.split('.').last : '';
    final bytes = await file.length();
    String? extracted;
    if (type == AttachmentType.file) {
      extracted = await _textExtractor.extractText(file, ext);
    }
    return ChatAttachment(
      id: _newId(),
      type: type,
      name: name,
      path: file.path,
      sizeBytes: bytes,
      extractedText: extracted,
    );
  }

  // ── Sending (enqueue) ──
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && pendingAttachments.isEmpty) return;

    final id = _newId();
    final attachments = List<ChatAttachment>.from(pendingAttachments);
    pendingAttachments.clear();

    File? imageFile;
    if (attachments.isNotEmpty && attachments.first.type == AttachmentType.image) {
      imageFile = File(attachments.first.path);
    }

    final userMessage = ChatMessage(
      id: id,
      role: MessageRole.user,
      content: trimmed,
      attachments: attachments,
      status: _isProcessingQueue ? MessageStatus.queued : MessageStatus.sending,
    );
    messages.add(userMessage);
    _lastUserMessage = userMessage;
    notifyListeners();

    _messageQueue.addLast(_QueuedRequest(id: id, text: trimmed, imageFile: imageFile));
    if (!_isProcessingQueue) _processQueue();
  }

  // ── Queue processor ──
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      final request = _messageQueue.removeFirst();
      _setMessageStatus(request.id, MessageStatus.sending);

      // ── Insert thinking placeholder directly after the user message ──
      final userMsgIndex = messages.indexWhere((m) => m.id == request.id);
      if (userMsgIndex == -1) continue;

      final thinkingId = '${request.id}_typing';
      final thinkingMsg = ChatMessage(
        id: thinkingId,
        role: MessageRole.ai,
        content: 'AURA is thinking…',
        status: MessageStatus.sending,
      );
      messages.insert(userMsgIndex + 1, thinkingMsg);
      notifyListeners();

      try {
        String? imageDataUri;
        if (request.imageFile != null) {
          imageDataUri = await ImageUtils.fileToBase64DataUri(request.imageFile!);
        }

        final response = await _sendMessage(
          userMessage: request.text.isEmpty ? 'What is in this image?' : request.text,
          imageBase64: imageDataUri,
          history: _buildHistory(),
        );

        // ── Replace thinking placeholder with the actual answer ──
        final answerId = '${request.id}_ans';
        final answerMsg = ChatMessage(
          id: answerId,
          role: MessageRole.ai,
          content: response,
          status: MessageStatus.sent,
        );
        _replaceMessage(thinkingId, answerMsg);
        _setStatusInPlace(request.id, MessageStatus.sent);
        notifyListeners();
        _speakResponse(response);
      } catch (_) {
        final errorMsg = ChatMessage(
          id: '${request.id}_err',
          role: MessageRole.ai,
          content: "Couldn't answer this one – tap to retry.",
          status: MessageStatus.error,
        );
        _replaceMessage(thinkingId, errorMsg);
        _setStatusInPlace(request.id, MessageStatus.error);
        notifyListeners();
      }
    }

    _isProcessingQueue = false;
  }

  void _replaceMessage(String oldId, ChatMessage newMessage) {
    final index = messages.indexWhere((m) => m.id == oldId);
    if (index != -1) {
      messages[index] = newMessage;
    } else {
      messages.add(newMessage);
    }
  }

  void _setMessageStatus(String id, MessageStatus status) {
    final i = messages.indexWhere((m) => m.id == id);
    if (i != -1) {
      messages[i].status = status;
      notifyListeners();
    }
  }

  void _setStatusInPlace(String id, MessageStatus status) {
    final i = messages.indexWhere((m) => m.id == id);
    if (i != -1) messages[i].status = status;
  }

  List<Map<String, String>> _buildHistory() {
    return messages
        .where((m) => m.status == MessageStatus.sent)
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();
  }

  // ── Retry ──
  Future<void> retry(ChatMessage failedAiMessage) async {
    if (_lastUserMessage == null) return;
    messages.remove(failedAiMessage);
    _messageQueue.addFirst(_QueuedRequest(
      id: _lastUserMessage!.id,
      text: _lastUserMessage!.content,
      imageFile: _lastUserMessage!.attachments.isNotEmpty
          ? File(_lastUserMessage!.attachments.first.path)
          : null,
    ));
    notifyListeners();
    if (!_isProcessingQueue) _processQueue();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

class _QueuedRequest {
  final String id;
  final String text;
  final File? imageFile;
  _QueuedRequest({required this.id, required this.text, this.imageFile});
}

// ============================================================================
// SHARED HELPERS
// ============================================================================

void _copyToClipboard(BuildContext context, String text) {
  if (text.trim().isEmpty) return;
  Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard', style: TextStyle(color: AuraColors.textPrimary)),
        backgroundColor: AuraColors.surfaceOverlay,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AuraRadii.sm)),
      ),
    );
}

/// Scale-down-on-press wrapper used everywhere instead of default ripples,
/// for a quieter, more premium feel consistent with the rest of the UI.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleDown = 0.93,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scaleDown;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// CHAT SCREEN
// ============================================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.sendMessage});

  final SendMessageFn sendMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider _provider;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _showVoiceOverlay = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _provider = ChatProvider(sendMessage: widget.sendMessage);
    _provider.addListener(_scrollToBottomSoon);
    _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _provider.removeListener(_scrollToBottomSoon);
    _provider.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty && _provider.pendingAttachments.isEmpty) return;
    _textController.clear();
    _focusNode.unfocus();
    await _provider.sendUserMessage(text);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final attachment =
          await _provider.buildAttachmentFromFile(File(file.path), type: AttachmentType.image);
      _provider.addAttachment(attachment);
    } catch (_) {
      _showSnack('Could not access camera or gallery.');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'csv'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final attachment =
          await _provider.buildAttachmentFromFile(File(path), type: AttachmentType.file);
      _provider.addAttachment(attachment);
    } catch (_) {
      _showSnack('Could not open the document picker.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: AuraColors.textPrimary)),
          backgroundColor: AuraColors.surfaceOverlay,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AuraRadii.sm)),
        ),
      );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onFile: () {
          Navigator.pop(context);
          _pickFile();
        },
      ),
    );
  }

  void _openVoiceOverlay() {
    _focusNode.unfocus();
    setState(() => _showVoiceOverlay = true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AuraColors.background,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildMessageList()),
                  Consumer<ChatProvider>(
                    builder: (_, provider, __) => AttachmentPreviewBar(
                      attachments: provider.pendingAttachments,
                      onRemove: provider.removeAttachment,
                    ),
                  ),
                  ChatInputBar(
                    controller: _textController,
                    focusNode: _focusNode,
                    onSend: _handleSend,
                    onAttach: _showAttachmentSheet,
                    onVoice: _openVoiceOverlay,
                  ),
                ],
              ),
            ),
            if (_showVoiceOverlay)
              Positioned.fill(
                child: VoiceInputOverlay(
                  onResult: (text) {
                    _textController.text = text;
                    _textController.selection = TextSelection.collapsed(offset: text.length);
                    _handleSend();
                  },
                  onClose: () => setState(() => _showVoiceOverlay = false),
                  ttsInstance: _tts,
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AuraColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AuraSpacing.md,
      title: const Row(
        children: [
          AiAvatarRing(size: 32),
          SizedBox(width: AuraSpacing.sm),
          Text(
            'Assistant',
            style: TextStyle(
              color: AuraColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call),
          tooltip: 'Live call',
          onPressed: () {
            final aiService = context.read<AiChatService>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveCallScreen(aiService: aiService),
              ),
            );
          },
        ),
        Consumer<ChatProvider>(
          builder: (context, provider, _) => IconButton(
            icon: Icon(
              provider.speakerOn ? Icons.volume_up : Icons.volume_off,
            ),
            tooltip: provider.speakerOn ? 'Mute replies' : 'Read replies aloud',
            onPressed: provider.toggleSpeaker,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.messages.isEmpty) {
          return const ChatEmptyState();
        }
        final width = MediaQuery.of(context).size.width;
        final maxContentWidth = width > 700 ? 640.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AuraSpacing.md,
                vertical: AuraSpacing.lg,
              ),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final message = provider.messages[index];
                if (message.content == '···' && message.id.endsWith('_typing')) {
                  return const TypingIndicatorBubble();
                }
                return message.role == MessageRole.user
                    ? UserMessageBubble(message: message)
                    : AiMessageBubble(
                        message: message,
                        onRetry: () => provider.retry(message),
                      );
              },
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AiAvatarRing(size: 52),
            const SizedBox(height: AuraSpacing.lg),
            const Text(
              'Ask me anything',
              style: TextStyle(
                color: AuraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AuraSpacing.xs),
            Text(
              'Start a conversation, attach a file, or use voice input.',
              textAlign: TextAlign.center,
              style: AuraText.bodySecondary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ============================================================================
// AVATAR
// ============================================================================

class AiAvatarRing extends StatelessWidget {
  const AiAvatarRing({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AuraColors.accentGradient,
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.background,
        ),
        child: Center(
          child: Container(
            width: size * 0.36,
            height: size * 0.36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuraColors.accentGradient,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BUBBLES
// ============================================================================

class MessageTailPainter extends CustomPainter {
  MessageTailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant MessageTailPainter oldDelegate) => oldDelegate.color != color;
}

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AuraSpacing.md, left: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AuraSpacing.xs),
                child: Wrap(
                  spacing: AuraSpacing.xs,
                  runSpacing: AuraSpacing.xs,
                  alignment: WrapAlignment.end,
                  children:
                      message.attachments.map((a) => AttachmentChip(attachment: a)).toList(),
                ),
              ),
            if (message.content.isNotEmpty)
              GestureDetector(
                onLongPress: () => _copyToClipboard(context, message.content),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AuraColors.surfaceRaised,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AuraRadii.lg),
                          topRight: Radius.circular(AuraRadii.lg),
                          bottomLeft: Radius.circular(AuraRadii.lg),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(message.content, style: AuraText.body),
                    ),
                    Positioned(
                      right: -6,
                      bottom: 0,
                      child: CustomPaint(
                        size: const Size(8, 8),
                        painter: MessageTailPainter(AuraColors.surfaceRaised),
                      ),
                    ),
                  ],
                ),
              ),
            if (message.status == MessageStatus.queued)
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 2),
                child: Text(
                  'Queued',
                  style: TextStyle(fontSize: 11, color: AuraColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 260.ms, curve: Curves.easeOut);
  }
}

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({super.key, required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  Widget _buildThinkingBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuraSpacing.lg, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAvatarRing(),
          const SizedBox(width: AuraSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AuraColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AuraRadii.md),
              ),
              child: Text(
                message.content,
                style: AuraText.body.copyWith(color: AuraColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.status == MessageStatus.sending) {
      return _buildThinkingBubble(message);
    }

    final isError = message.status == MessageStatus.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AuraSpacing.lg, right: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _copyToClipboard(context, message.content),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiAvatarRing(),
            const SizedBox(width: AuraSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: isError
                        ? AuraText.body.copyWith(color: AuraColors.danger)
                        : AuraText.body,
                  ),
                  const SizedBox(height: AuraSpacing.sm),
                  Row(
                    children: [
                      ActionChipButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: () => _copyToClipboard(context, message.content),
                      ),
                      const SizedBox(width: AuraSpacing.xs),
                      ActionChipButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry',
                        onTap: onRetry,
                      ),
                      const SizedBox(width: AuraSpacing.xs),
                      ActionChipButton(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onTap: () => Share.share(message.content),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AuraColors.surface,
          borderRadius: BorderRadius.circular(AuraRadii.pill),
          border: Border.all(color: AuraColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AuraColors.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: AuraText.chip),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TYPING INDICATOR
// ============================================================================

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuraSpacing.lg),
      child: Row(
        children: [
          const AiAvatarRing(),
          const SizedBox(width: AuraSpacing.sm),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [AuraColors.violet, AuraColors.cyan, AuraColors.violet],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-1.6 + 3.2 * t, 0),
                  end: Alignment(0.4 + 3.2 * t, 0),
                ).createShader(bounds),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.6,
                            end: 1.0,
                            duration: 500.ms,
                            delay: (i * 160).ms,
                            curve: Curves.easeInOut,
                          ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ATTACHMENTS
// ============================================================================

class AttachmentChip extends StatelessWidget {
  const AttachmentChip({super.key, required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.type == AttachmentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AuraRadii.sm),
        child: Image.file(
          File(attachment.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(AuraRadii.sm),
        border: Border.all(color: AuraColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_rounded, size: 16, color: AuraColors.cyan),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: AuraText.bodySecondary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class AttachmentPreviewBar extends StatelessWidget {
  const AttachmentPreviewBar({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<ChatAttachment> attachments;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 88,
      margin: const EdgeInsets.only(bottom: AuraSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: AuraSpacing.sm),
        itemBuilder: (context, index) {
          final a = attachments[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (a.type == AttachmentType.image)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AuraRadii.md),
                  child: Image.file(File(a.path), width: 72, height: 72, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AuraColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AuraRadii.md),
                    border: Border.all(color: AuraColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insert_drive_file_rounded, color: AuraColors.cyan, size: 20),
                      const SizedBox(height: 4),
                      Text(a.extension, style: AuraText.caption),
                    ],
                  ),
                ),
              Positioned(
                top: -6,
                right: -6,
                child: PressableScale(
                  onTap: () => onRemove(a.id),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AuraColors.surfaceOverlay,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: AuraColors.textPrimary),
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onFile,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AuraSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AuraSpacing.md),
        decoration: BoxDecoration(
          color: AuraColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AuraRadii.lg),
          border: Border.all(color: AuraColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AuraSpacing.md),
              decoration: BoxDecoration(
                color: AuraColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            _SheetOption(icon: Icons.photo_camera_rounded, label: 'Take a photo', onTap: onCamera),
            _SheetOption(
                icon: Icons.photo_library_rounded, label: 'Choose from gallery', onTap: onGallery),
            _SheetOption(icon: Icons.attach_file_rounded, label: 'Choose a document', onTap: onFile),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.15, end: 0, duration: 220.ms, curve: Curves.easeOut).fadeIn();
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.lg, vertical: AuraSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AuraColors.surface,
                borderRadius: BorderRadius.circular(AuraRadii.sm),
              ),
              child: Icon(icon, size: 18, color: AuraColors.cyan),
            ),
            const SizedBox(width: AuraSpacing.md),
            Text(label, style: AuraText.body),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INPUT BAR
// ============================================================================

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoice;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: AuraSpacing.md,
        right: AuraSpacing.md,
        top: AuraSpacing.sm,
        bottom: AuraSpacing.sm + bottomPadding * 0.3,
      ),
      decoration: const BoxDecoration(
        color: AuraColors.background,
        border: Border(top: BorderSide(color: AuraColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RoundIconButton(icon: Icons.add_rounded, onTap: widget.onAttach),
          const SizedBox(width: AuraSpacing.xs),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.md, vertical: 10),
                decoration: BoxDecoration(
                  color: AuraColors.surface,
                  borderRadius: BorderRadius.circular(AuraRadii.pill),
                  border: Border.all(color: AuraColors.divider),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: AuraText.body,
                  cursorColor: AuraColors.cyan,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: AuraColors.textMuted, fontSize: 15.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AuraSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: _hasText
                ? _SendButton(key: const ValueKey('send'), onTap: widget.onSend)
                : _RoundIconButton(
                    key: const ValueKey('mic'),
                    icon: Icons.mic_none_rounded,
                    onTap: widget.onVoice,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: AuraColors.surfaceRaised, shape: BoxShape.circle),
        child: Icon(icon, color: AuraColors.textSecondary, size: 21),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(gradient: AuraColors.accentGradient, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21),
      ),
    );
  }
}
