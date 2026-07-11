import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/tokens.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<String> milestones = [];
  List<SubTask> subtasks = [];

  void _addGoal() async {
    final goalService = context.read<GoalService>();
    final goal = Goal(
      id: const Uuid().v4(),
      title: _titleCtrl.text,
      description: _descCtrl.text,
      milestones: List.from(milestones),
      subtasks: List.from(subtasks),
      createdAt: DateTime.now(),
    );
    await goalService.addGoal(goal);
    _titleCtrl.clear();
    _descCtrl.clear();
    milestones.clear();
    subtasks.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalService>().goals;
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(hintText: 'Goal title'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addGoal),
              ],
            ),
          ),
          Expanded(
            child: goals.isEmpty
                ? const Center(child: Text('No goals yet'))
                : ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (_, i) {
                      final g = goals[i];
                      return Card(
                        color: AppColors.surfaceRaised,
                        child: ListTile(
                          title: Text(g.title),
                          subtitle: Text('${(g.progress * 100).toInt()}% complete'),
                          onTap: () {
                            // navigate to detail/edit (future)
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
