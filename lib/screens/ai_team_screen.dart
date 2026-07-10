import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/agent_team_service.dart';
import '../models/agent_role.dart';

class AITeamScreen extends StatelessWidget {
  const AITeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Team')),
      body: StreamBuilder<List<AgentRole>>(
        stream: context.read<AgentTeamService>().teamRoles,
        builder: (ctx, snap) {
          final roles = snap.data ?? [];
          if (roles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final root = roles.firstWhere((r) => r.parentId.isEmpty,
              orElse: () => roles.first);
          return ListView(
            padding: const EdgeInsets.all(space4),
            children: [_buildNode(root, roles, 0)],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => context.read<AgentTeamService>().seedTeam(),
      ),
    );
  }

  Widget _buildNode(AgentRole role, List<AgentRole> all, int depth) {
    final children = all.where((r) => r.parentId == role.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 24.0, bottom: space2),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space2),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(radiusMd),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                children.isEmpty ? Icons.person : Icons.group,
                color: AppColors.accentViolet,
              ),
              const SizedBox(width: space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(role.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              if (children.isNotEmpty) ...[
                const Spacer(),
                Text('${children.length} sub-agents',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
              ],
            ],
          ),
        ),
        ...children.map((child) => _buildNode(child, all, depth + 1)),
      ],
    );
  }
}
