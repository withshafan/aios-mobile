import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_runner_service.dart';

class AutonomousRunnerScreen extends StatefulWidget {
  const AutonomousRunnerScreen({super.key});

  @override
  State<AutonomousRunnerScreen> createState() => _AutonomousRunnerScreenState();
}

class _AutonomousRunnerScreenState extends State<AutonomousRunnerScreen> {
  final _goalCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final runner = context.watch<TaskRunnerService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Autonomous Runner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter a high-level goal...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: runner.isRunning ? null : () => runner.executeGoal(_goalCtrl.text),
              child: const Text('Start Autonomous Agent'),
            ),
            const Divider(),
            if (runner.isRunning) const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(runner.status, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
