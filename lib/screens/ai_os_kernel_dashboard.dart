import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_llm_service.dart';
import '../services/agent_team_service.dart';
import '../models/llm_provider.dart';
import '../models/agent_role.dart';

class AIOSKernelDashboard extends StatelessWidget {
  const AIOSKernelDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI OS Kernel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard('Enabled LLM Providers', StreamBuilder<List<LLMProvider>>(
              stream: context.read<MultiLLMService>().providers,
              builder: (_, snap) => Text('${snap.data?.where((p) => p.isEnabled).length ?? 0} active'),
            )),
            const SizedBox(height: 8),
            _buildStatusCard('AI Team Size', StreamBuilder<List<AgentRole>>(
              stream: context.read<AgentTeamService>().teamRoles,
              builder: (_, snap) => Text('${snap.data?.length ?? 0} agents'),
            )),
            const SizedBox(height: 8),
            _buildStatusCard('Active Research Missions', const Text('0 active')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, Widget value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            value,
          ],
        ),
      ),
    );
  }
}
