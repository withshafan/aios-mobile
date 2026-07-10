import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/planner_service.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_fill;
      case 'failed':
        return Icons.error;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerService>();
    final tasks = planner.tasks;

    return Column(
      children: [
        if (tasks.isEmpty)
          const Expanded(
            child: Center(child: Text('No plan steps yet. Ask AURA to plan something.')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final task = tasks[i];
                final status = task['status'] as String;
                return Card(
                  child: ListTile(
                    leading: Icon(_statusIcon(status), color: _statusColor(status)),
                    title: Text(task['description'] ?? ''),
                    subtitle: Text('Status: $status'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          planner.deleteTask(task['id']);
                        } else {
                          planner.updateStatus(task['id'], value);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'pending', child: Text('Pending')),
                        const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                        const PopupMenuItem(value: 'completed', child: Text('Completed')),
                        const PopupMenuItem(value: 'failed', child: Text('Failed')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
