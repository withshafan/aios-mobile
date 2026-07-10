import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/cognitive_state_service.dart';
import '../models/cognitive_state.dart';

class CognitiveStateScreen extends StatelessWidget {
  const CognitiveStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cognitive State')),
      body: StreamBuilder<CognitiveState>(
        stream: context.read<CognitiveStateService>().stateStream,
        builder: (ctx, snap) {
          final state = snap.data ?? CognitiveState();
          return ListView(
            padding: const EdgeInsets.all(space4),
            children: [
              _buildCard('Current Focus', state.currentFocus),
              _buildCard('Confidence', '${(state.confidence * 100).toInt()}%'),
              _buildCard('Operating Mode', state.operatingMode),
              _buildCard('Background Tasks', state.backgroundTasks.join('\n')),
              _buildCard('Pending Approvals', state.pendingApprovals.join('\n')),
              _buildCard('Next Planned', state.nextPlanned),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Card(
      color: AppColors.surfaceRaised,
      margin: const EdgeInsets.only(bottom: space3),
      child: Padding(
        padding: const EdgeInsets.all(space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: space1),
            Text(value.isNotEmpty ? value : 'None', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
