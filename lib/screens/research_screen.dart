import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/deepseek_service.dart';
import '../services/analytics_service.dart';
import '../services/plugin_service.dart';
import '../services/system_prompt_service.dart';
import '../services/planner_service.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _topicCtrl = TextEditingController();
  String _progress = '';
  List<String> _sources = [];
  bool _isResearching = false;
  Timer? _timer;

  void _startResearch() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      _isResearching = true;
      _progress = 'Researching...';
    });

    final deepseek = DeepSeekService(
      context.read<AnalyticsService>(),
    );

    // Simulate 3 research cycles
    for (int i = 0; i < 3; i++) {
      final response = await deepseek.sendMessage(
        'Research about $topic. Give me key findings and sources.',
        null,
      );
      setState(() {
        _progress = response.text;
        _sources.add('Source $i: example.com/$i');
      });
      await Future.delayed(const Duration(seconds: 5)); // simulate delay
    }

    setState(() {
      _isResearching = false;
      _progress += '\n\nResearch completed.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(hintText: 'Research topic'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isResearching ? null : _startResearch,
            child: Text(_isResearching ? 'Researching...' : 'Start Research'),
          ),
          const SizedBox(height: 20),
          if (_progress.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Text(_progress),
              ),
            ),
        ],
      ),
    );
  }
}
