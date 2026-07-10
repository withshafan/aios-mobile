import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/aura_theme.dart';
import 'memory_screen.dart';
import 'android_screen.dart';
import 'files_screen.dart';
import 'documents_screen.dart';
import 'browser_screen.dart';
import 'calendar_screen.dart';
import 'plugins_screen.dart';
import 'analytics_screen.dart';
import 'goal_screen.dart';
import 'knowledge_graph_screen.dart';
import 'ai_team_screen.dart';
import 'connected_services_screen.dart';
import 'approval_matrix_screen.dart';
import 'strategic_missions_screen.dart';
import 'research_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AuraTheme>()!;
    final items = [
      _MoreItem('Memory', Icons.memory, const MemoryScreen()),
      _MoreItem('Android Device', Icons.phone_android, const AndroidScreen()),
      _MoreItem('Files', Icons.folder, const FilesScreen()),
      _MoreItem('Documents', Icons.article, const DocumentsScreen()),
      _MoreItem('Browser', Icons.language, const BrowserScreen()),
      _MoreItem('Calendar', Icons.calendar_today, const CalendarScreen()),
      _MoreItem('Plugins', Icons.extension, const PluginsScreen()),
      _MoreItem('Analytics', Icons.analytics, const AnalyticsScreen()),
      _MoreItem('Goals', Icons.flag, const GoalScreen()),
      _MoreItem('Knowledge Graph', Icons.hub, const KnowledgeGraphScreen()),
      _MoreItem('AI Team', Icons.group_work, const AITeamScreen()),
      _MoreItem('Connected Services', Icons.cloud_queue, const ConnectedServicesScreen()),
      _MoreItem('Approval Matrix', Icons.gavel, const ApprovalMatrixScreen()),
      _MoreItem('Strategic Missions', Icons.flight_takeoff, const StrategicMissionsScreen()),
      _MoreItem('Research', Icons.science, const ResearchScreen()),
      _MoreItem('Settings', Icons.settings, const SettingsScreen()),
    ];

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(space4),
      children: items.map((item) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen));
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(space3),
                decoration: BoxDecoration(
                  color: theme.surfaceRaised,
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Icon(item.icon, size: 32, color: AppColors.accentViolet),
              ),
              const SizedBox(height: space1),
              Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MoreItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const _MoreItem(this.label, this.icon, this.screen);
}
