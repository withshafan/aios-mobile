import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/email_service.dart';
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
      final response = await widget.gemini.sendMessageWithFile(text, history, file);
      
      await memory.sendMessage(
        response.text, 
        isUser: false,
        imageUrl: response.imageUrl,
        sources: response.sources,
      );
      widget.voice.speak(response.text);

      if (response.taskToCreate != null) {
        final cmd = response.taskToCreate!;
        await context.read<TaskService>().createFromCommand(
          cmd.title,
          cmd.dueDate,
          cmd.description,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "${cmd.title}" created!')),
        );
      }

      if (response.emailToSend != null) {
        final cb = context.read<CircuitBreakerService>();
        if (await cb.isAgentTripped('email')) {
          await memory.sendMessage('Email agent is currently tripped due to too many failures. Please try again later or reset in System Health.', isUser: false);
        } else {
          final cmd = response.emailToSend!;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Send email?'),
              content: Text('To: ${cmd.to}\nSubject: ${cmd.subject}\nBody: ${cmd.body}'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                TextButton(
                  child: const Text('Send'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final emailService = EmailService();
            try {
              final result = await emailService.sendEmail(
                to: cmd.to,
                subject: cmd.subject,
                body: cmd.body,
              );
              await cb.clearFailures('email');
              await memory.sendMessage(result, isUser: false);
              widget.voice.speak(result);
            } catch (e) {
              await cb.recordFailure('email');
              await memory.sendMessage('Failed to send email: $e', isUser: false);
            }
          } else {
            await memory.sendMessage('Email cancelled.', isUser: false);
          }
        }
      }

      if (response.browserUrl != null) {
        final url = response.browserUrl!;
        context.read<BrowserService>().loadUrl(url);
      }

      if (response.calendarEvent != null) {
        final cb = context.read<CircuitBreakerService>();
        if (await cb.isAgentTripped('calendar')) {
          await memory.sendMessage('Calendar agent is currently tripped due to too many failures. Please try again later or reset in System Health.', isUser: false);
        } else {
          final cmd = response.calendarEvent!;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Create calendar event?'),
              content: Text('${cmd.summary}\nFrom: ${cmd.start}\nTo: ${cmd.end}'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                TextButton(
                  child: const Text('Create'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final auth = context.read<AuthService>();
            final googleUser = auth.googleUser;
            if (googleUser != null) {
              final calendarService = CalendarService();
              try {
                await calendarService.createEvent(
                  googleUser,
                  summary: cmd.summary,
                  start: cmd.start,
                  end: cmd.end,
                  description: cmd.description,
                );
                await cb.clearFailures('calendar');
                await memory.sendMessage('Event "${cmd.summary}" added to your calendar.', isUser: false);
              } catch (e) {
                await cb.recordFailure('calendar');
                await memory.sendMessage('Failed to create event: $e', isUser: false);
              }
            } else {
              await memory.sendMessage('Calendar access not available. Please re-login.', isUser: false);
            }
          } else {
            await memory.sendMessage('Event creation cancelled.', isUser: false);
          }
        }
      }

      if (response.plannerAction != null) {
        // Planner already updated, just show confirmation
      }

      if (response.generateDocument != null) {
        final cmd = response.generateDocument!;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Generate Document?'),
            content: Text('Title: ${cmd.title}\nFormat: ${cmd.format}'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              TextButton(
                child: const Text('Generate'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          try {
            final outputService = DocumentOutputService();
            String path = '';
            if (cmd.format == 'pdf') {
              path = await outputService.generatePdf(cmd.title, [cmd.content]);
            } else if (cmd.format == 'xlsx') {
              // Very basic CSV parsing
              final rows = cmd.content.split('\n').map((row) => row.split(',')).toList();
              path = await outputService.generateExcel(cmd.title, rows);
            } else if (cmd.format == 'docx') {
              path = await outputService.generateDocx(cmd.title, [cmd.content]);
            } else if (cmd.format == 'pptx') {
              path = await outputService.generatePptx(cmd.title, [cmd.content]);
            }
            
            final audit = AuditService();
            await audit.log(
              agent: 'document',
              action: 'generate_document',
              tier: 'reversible',
              details: {'title': cmd.title, 'format': cmd.format, 'path': path},
            );
            
            await memory.sendMessage('Document saved at: $path', isUser: false);
            OpenFile.open(path);
          } catch (e) {
            await memory.sendMessage('Failed to generate document: $e', isUser: false);
          }
        } else {
          await memory.sendMessage('Document generation cancelled.', isUser: false);
        }
      }

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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isLoading && index == messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.network(message.imageUrl!),
              ),
            Text(
              message.content,
              style: const TextStyle(fontSize: 16),
            ),
            if (message.sources != null && message.sources!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Sources: ${message.sources!.join(", ")}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFile,
              ),
              IconButton(
                icon: Icon(widget.voice.isListening ? Icons.mic : Icons.mic_none),
                onPressed: _startVoiceInput,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
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
