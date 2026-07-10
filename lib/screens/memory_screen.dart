import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../models/chat_message.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memory = context.watch<MemoryService>();
    final messages = memory.messages;

    return Column(
      children: [
        if (messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Memory'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all conversations?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      TextButton(
                        child: const Text('Clear'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await memory.clearMemory();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'No conversations yet.\nStart chatting!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          msg.isUser ? Icons.person : Icons.auto_awesome,
                          color: msg.isUser ? Colors.blue : Colors.green,
                        ),
                        title: Text(
                          msg.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${msg.isUser ? "You" : "AI"} • ${msg.timestamp.toString().substring(0, 19)}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
