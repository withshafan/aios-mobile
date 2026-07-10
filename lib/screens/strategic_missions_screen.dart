import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import 'goal_screen.dart';

class StrategicMissionsScreen extends StatelessWidget {
  const StrategicMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalService>().goals;
    return Scaffold(
      appBar: AppBar(title: const Text('Strategic Missions')),
      body: goals.isEmpty
          ? const Center(child: Text('No missions yet. Create one from Goals.'))
          : ListView.builder(
              padding: const EdgeInsets.all(space4),
              itemCount: goals.length,
              itemBuilder: (_, i) {
                final goal = goals[i];
                return Card(
                  color: AppColors.surfaceRaised,
                  margin: const EdgeInsets.only(bottom: space3),
                  child: Padding(
                    padding: const EdgeInsets.all(space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: space2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(radiusFull),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            backgroundColor: AppColors.surfaceOverlay,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goal.progress >= 1.0 ? AppColors.accentSuccess : AppColors.accentViolet,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: space2),
                        Text('${(goal.progress * 100).toInt()}% complete',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Navigate to goal creation screen (we'll reuse GoalScreen)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalScreen()));
        },
      ),
    );
  }
}
