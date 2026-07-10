import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_prompt_service.dart';

class SystemPromptScreen extends StatefulWidget {
  const SystemPromptScreen({super.key});

  @override
  State<SystemPromptScreen> createState() => _SystemPromptScreenState();
}

class _SystemPromptScreenState extends State<SystemPromptScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<SystemPromptService>().currentPrompt;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await context.read<SystemPromptService>().updatePrompt(_controller.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System prompt updated.')),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Prompt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your system prompt...',
                ),
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final defaultPrompt = SystemPromptService.defaultPrompt;
                    _controller.text = defaultPrompt;
                    context.read<SystemPromptService>().updatePrompt(defaultPrompt);
                  },
                  child: const Text('Reset to default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
