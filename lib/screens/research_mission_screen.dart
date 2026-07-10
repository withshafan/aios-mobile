import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/openrouter_service.dart';
import '../services/analytics_service.dart';
import '../services/plugin_service.dart';
import '../services/system_prompt_service.dart';
import '../services/planner_service.dart';

class ResearchMissionScreen extends StatefulWidget {
  const ResearchMissionScreen({super.key});

  @override
  State<ResearchMissionScreen> createState() => _ResearchMissionScreenState();
}

class _ResearchMissionScreenState extends State<ResearchMissionScreen> {
  final _topicCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1'); // hours
  bool _isResearching = false;
  String _progressLog = '';
  Timer? _timer;

  void _startResearch() async {
    final topic = _topicCtrl.text.trim();
    final hours = int.tryParse(_durationCtrl.text) ?? 1;
    if (topic.isEmpty) return;
    setState(() {
      _isResearching = true;
      _progressLog = 'Starting $hours hour(s) research on "$topic"...\n';
    });

    final _aiService = OpenRouterService(
      context.read<AnalyticsService>(),
    );

    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(hours: hours));

    int cycle = 0;
    while (DateTime.now().isBefore(endTime)) {
      cycle++;
      final prompt = 'Research cycle $cycle for "$topic". Provide new findings, sources, and key insights.';
      final response = await _aiService.sendMessage(prompt, null);
      setState(() {
        _progressLog += '--- Cycle $cycle ---\n${response.text}\n\n';
      });
      // Wait 1 minute between cycles (adjustable)
      await Future.delayed(const Duration(minutes: 1));
    }
    setState(() {
      _progressLog += 'Research completed.\n';
      _isResearching = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topicCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autonomous Research')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _topicCtrl, decoration: const InputDecoration(labelText: 'Research Topic')),
            const SizedBox(height: 8),
            TextField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Duration (hours)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isResearching ? null : _startResearch,
              child: Text(_isResearching ? 'Researching...' : 'Start Research'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_progressLog, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
