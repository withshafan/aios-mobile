import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;

    return tasks.isEmpty
        ? const Center(
            child: Text(
              'No tasks yet.\nAsk the AI to remind you of something!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final dateStr = DateFormat('MMM dd, yyyy – hh:mm a').format(task.dueDate);
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => taskService.toggleComplete(task.id, task.isCompleted),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null && task.description!.isNotEmpty)
                        Text(task.description!),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => taskService.deleteTask(task.id),
                  ),
                ),
              );
            },
          );
  }
}
