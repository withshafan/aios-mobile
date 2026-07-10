import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/agent_team_service.dart';
import '../models/agent_role.dart';

class AgentTeamScreen extends StatelessWidget {
  const AgentTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Team Collaboration')),
      body: StreamBuilder<List<AgentRole>>(
        stream: context.read<AgentTeamService>().teamRoles,
        builder: (ctx, snap) {
          final roles = snap.data ?? [];
          if (roles.isEmpty) {
            return const Center(child: Text('No team yet. Initializing...'));
          }
          // Build hierarchy tree
          final root = roles.firstWhere((r) => r.parentId.isEmpty);
          return _buildNode(root, roles, context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => context.read<AgentTeamService>().seedTeam(),
      ),
    );
  }

  Widget _buildNode(AgentRole role, List<AgentRole> all, BuildContext context) {
    final children = all.where((r) => r.parentId == role.id).toList();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(role.name),
            subtitle: Text(role.description),
          ),
          ...children.map((child) => _buildNode(child, all, context)),
        ],
      ),
    );
  }
}
