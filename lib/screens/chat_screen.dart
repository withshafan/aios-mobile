import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/email_service.dart';
import '../services/browser_service.dart';
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
    if (text.isEmpty) return;
    _controller.clear();
    final memory = context.read<MemoryService>();
    await memory.sendMessage(text, isUser: true);

    List<String> history = memory.messages
        .map((m) => m.isUser ? 'User: ${m.content}' : 'AI: ${m.content}')
        .toList();

    setState(() => _isLoading = true);

    try {
      final response = await widget.gemini.sendMessage(text, history);
      
      await memory.sendMessage(response.text, isUser: false);
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
        // It's already handled in the general response text handling
        // But we could add a special UI thing here if wanted
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
        child: Text(
          message.content,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
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
    );
  }
}
