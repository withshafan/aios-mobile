import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cognitive_state_service.dart';
import '../../services/attention_service.dart';
import '../../models/cognitive_state.dart';

class ExecutiveDashboard extends StatelessWidget {
  const ExecutiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AURA Command Center')),
      body: StreamBuilder<CognitiveState>(
        stream: context.read<CognitiveStateService>().stateStream,
        builder: (ctx, snap) {
          final state = snap.data ?? CognitiveState();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Current Focus', [state.currentFocus, 'Confidence: ${(state.confidence*100).toInt()}%', 'Mode: ${state.operatingMode}']),
                _buildSection('Background Tasks', state.backgroundTasks),
                _buildSection('Pending Approvals', state.pendingApprovals),
                _buildSection('Waiting Conditions', state.waitingConditions),
                _buildSection('Next Planned', [state.nextPlanned]),
                // Attention stream
                _buildAttentionStream(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...items.where((i) => i.isNotEmpty).map((item) => Text('• $item')),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionStream(BuildContext context) {
    return StreamBuilder<List<AttentionItem>>(
      stream: context.read<AttentionService>().items,
      builder: (ctx, snap) {
        final items = snap.data?.where((i) => !i.isRead).toList() ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildSection('Attention Needed', items.map((i) => '${i.title} (Urgency: ${i.urgency})').toList());
      },
    );
  }
}
