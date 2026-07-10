import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/deepseek_service.dart';
import '../services/analytics_service.dart';
import '../services/plugin_service.dart';

class CodeExecutionScreen extends StatefulWidget {
  const CodeExecutionScreen({super.key});

  @override
  State<CodeExecutionScreen> createState() => _CodeExecutionScreenState();
}

class _CodeExecutionScreenState extends State<CodeExecutionScreen> {
  final _codeCtrl = TextEditingController();
  String _output = '';
  bool _running = false;

  Future<void> _runCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _running = true);
    // Use DeepSeek to predict the output (simulated execution)
    // We instantiate a temporary DeepSeekService just to get the response.
    // Assuming context.read gets the instances correctly.
    final deepseek = DeepSeekService(context.read<AnalyticsService>()); 
    final response = await deepseek.sendMessage(
      'Execute the following code and return only the raw output (do not explain):\n```\n$code\n```',
      null,
    );
    setState(() {
      _output = response.text;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Code Execution Sandbox')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Enter code (Python, JS, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run (Simulated)'),
              onPressed: _running ? null : _runCode,
            ),
            const Divider(),
            const Text('Output:'),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
