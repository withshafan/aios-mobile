import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/email_service.dart';
import '../services/browser_service.dart';
import 'dart:io';
import '../services/circuit_breaker_service.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_attachment.dart';
import '../services/file_ingestion_service.dart';
import '../services/document_output_service.dart';
import '../services/audit_service.dart';
import 'package:open_file/open_file.dart';
import '../services/calendar_service.dart';
import '../services/auth_service.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../theme/aura_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  final GeminiService gemini;
  final VoiceService voice;

  const ChatScreen({super.key, required this.gemini, required this.voice});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<FileAttachment> _attachments = [];
  final FileIngestionService _fileIngestion = FileIngestionService();
  String _agentAction = '';

  @override
  void initState() {
    super.initState();
    widget.voice.initStt();
  }

  void sendVoiceCommand(String text) {
    _controller.text = text;
    _sendMessage();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    
    final List<FileAttachment> attachments = List.from(_attachments);
    _attachments.clear();
    _controller.clear();
    
    final memory = context.read<MemoryService>();

    String userDisplay = text;
    if (attachments.isNotEmpty) {
      userDisplay += '\n📎 ${attachments.map((a) => a.fileName).join(', ')}';
    }
    await memory.sendMessage(userDisplay, isUser: true);

    List<String> history = memory.messages
        .map((m) => m.isUser ? 'User: ${m.content}' : 'AI: ${m.content}')
        .toList();

    setState(() => _isLoading = true);

    try {
      FileAttachment? file = attachments.isNotEmpty ? attachments.first : null;
      final response = await widget.gemini.sendMessage(text, history);
      
      await memory.sendMessage(
        response.text, 
        isUser: false,
      );
      widget.voice.speak(response.text);


    } catch (e) {
      await memory.sendMessage('Sorry, something went wrong.', isUser: false);
    } finally {
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  void _startVoiceInput() async {
    String? spokenText = await widget.voice.listen();
    if (spokenText != null && spokenText.isNotEmpty) {
      _controller.text = spokenText;
      _sendMessage();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<MemoryService>().messages;
    final theme = Theme.of(context).extension<AuraTheme>()!;
    final voiceService = context.watch<VoiceService>();

    return Stack(
      children: [
        Column(
          children: [
            // Agent activity banner
            if (_agentAction.isNotEmpty)
              Container(
                height: 36,
                width: double.infinity,
                color: AppColors.surfaceRaised,
                child: Row(
                  children: [
                    const SizedBox(width: space3),
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentCyan),
                    const SizedBox(width: space2),
                    Text(_agentAction, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(space4),
                itemCount: messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == messages.length) {
                    return _buildThinkingIndicator(theme);
                  }
                  final message = messages[index];
                  return _buildMessageBubble(message, theme);
                },
              ),
            ),
            _buildInputArea(theme),
          ],
        ),
        // Voice mode full-screen overlay
        if (voiceService.isListening)
          Positioned.fill(
            child: _buildVoiceOverlay(),
          ),
      ],
    );
  }

  Widget _buildThinkingIndicator(AuraTheme theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentViolet),
            ),
          ),
          const SizedBox(width: space2),
          Text('Aura is thinking...', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
        ],
      ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.02, end: 0),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, AuraTheme theme) {
    final isUser = message.isUser;
    final timestamp = message.timestamp;
    final timeStr = DateFormat('HH:mm').format(timestamp);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: space2, left: space10),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
          decoration: BoxDecoration(
            color: theme.surfaceRaised,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(radiusLg),
              topRight: Radius.circular(radiusLg),
              bottomLeft: Radius.circular(radiusLg),
              bottomRight: Radius.circular(radiusXs),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(message.imageUrl!),
                ),
              Text(message.content, style: TextStyle(color: theme.textPrimary)),
              if (message.sources != null && message.sources!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Sources: ${message.sources!.join(", ")}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: space1),
                  child: Text(timeStr, style: TextStyle(color: theme.textDisabled, fontSize: 11)),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).move(begin: const Offset(0, 10), end: const Offset(0, 0)),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: space3, right: space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: AppColors.gradientIdle),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.network(message.imageUrl!),
                      ),
                    Text(message.content, style: TextStyle(color: theme.textPrimary, height: 1.5)),
                    if (message.sources != null && message.sources!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Sources: ${message.sources!.join(", ")}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (timeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: space1),
                        child: Text(timeStr, style: TextStyle(color: theme.textDisabled, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).move(begin: const Offset(0, 8), end: const Offset(0, 0)),
      );
    }
  }

  Widget _buildInputArea(AuraTheme theme) {
    return Container(
      padding: const EdgeInsets.all(space3),
      color: theme.surfaceBase,
      child: Column(
        children: [
          if (_attachments.isNotEmpty)
            Wrap(
              children: _attachments.map((att) => Chip(
                label: Text(att.fileName, style: const TextStyle(fontSize: 12)),
                onDeleted: () => setState(() => _attachments.remove(att)),
              )).toList(),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                onPressed: _pickFile,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Message Aura...',
                    hintStyle: const TextStyle(color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.surfaceRaised,
                    contentPadding: const EdgeInsets.symmetric(horizontal: space4, vertical: space2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusFull),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: AppColors.textSecondary),
                onPressed: _startVoiceInput,
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.accentViolet),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOverlay() {
    return Container(
      color: AppColors.bgCanvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 900),
              builder: (context, scale, _) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: AppColors.gradientActive),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentViolet.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, size: 48, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: space7),
            const Text('Listening...', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: space10),
            TextButton(
              onPressed: () {
                context.read<VoiceService>().stopWakeWordListening();
                setState(() {}); // force rebuild to hide overlay
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        final mime = _mimeFromExtension(file.extension ?? '');
        final attachment = FileAttachment(
          fileName: file.name,
          mimeType: mime,
          bytes: bytes,
        );
        setState(() => _attachments.add(attachment));
      }
    }
  }

  String _mimeFromExtension(String ext) {
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      case 'md': return 'text/markdown';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      default: return 'application/octet-stream';
    }
  }
}
