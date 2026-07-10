import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/self_programming_service.dart';

class SelfProgrammingScreen extends StatefulWidget {
  const SelfProgrammingScreen({super.key});

  @override
  State<SelfProgrammingScreen> createState() => _SelfProgrammingScreenState();
}

class _SelfProgrammingScreenState extends State<SelfProgrammingScreen> {
  final _descCtrl = TextEditingController();
  String _generatedCode = '';

  Future<void> _generate() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    final code = await context.read<SelfProgrammingService>().generatePluginCode(desc);
    setState(() => _generatedCode = code);
  }

  Future<void> _install() async {
    if (_generatedCode.isEmpty) return;
    await context.read<SelfProgrammingService>().saveGeneratedPlugin(
          'AutoPlugin_${DateTime.now().millisecond}',
          _generatedCode,
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugin installed!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Self-Programming')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Describe the plugin you want'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _generate, child: const Text('Generate Code')),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_generatedCode, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
            if (_generatedCode.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Install Plugin'),
                onPressed: _install,
              ),
          ],
        ),
      ),
    );
  }
}
