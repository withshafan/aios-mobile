import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';
import '../services/auth_service.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/document_service.dart';
import '../services/plugin_service.dart';
import '../services/browser_service.dart';
import '../services/analytics_service.dart';
import '../services/system_prompt_service.dart';
import '../services/planner_service.dart';
import '../services/continuity_service.dart';
import 'chat_screen.dart';
import 'memory_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'android_screen.dart';
import 'files_screen.dart';
import 'documents_screen.dart';
import 'workflow_screen.dart';
import 'plugins_screen.dart';
import 'browser_screen.dart';
import 'calendar_screen.dart';
import 'analytics_screen.dart';
import 'goals_screen.dart';
import 'knowledge_graph_screen.dart';
import 'marketplace_screen.dart';
import 'research_mission_screen.dart';
import 'knowledge_base_screen.dart';
import 'approval_level_screen.dart';
import 'digital_twin_screen.dart';
import 'cognitive_state_screen.dart';
import 'world_model_screen.dart';
import 'life_timeline_screen.dart';
import 'attention_center_screen.dart';
import 'strategic_missions_screen.dart';
import 'curiosity_feed_screen.dart';
import 'opportunities_screen.dart';
import 'personal_coach_screen.dart';
import 'emotional_context_screen.dart';
import 'trust_reality_screen.dart';
import 'reality_verification_screen.dart';
import 'maintenance_screen.dart';
import 'personality_settings_screen.dart';
import 'connected_services_screen.dart';
import 'unified_search_screen.dart';
import 'llm_providers_screen.dart';
import 'agent_team_screen.dart';
import 'self_programming_screen.dart';
import 'ai_os_kernel_dashboard.dart';
import 'governance/action_tiers_screen.dart';
import 'governance/audit_log_screen.dart';
import 'governance/system_health_screen.dart';
import 'governance/memory_integrity_screen.dart';
import 'code_execution_screen.dart';
import 'autonomous_runner_screen.dart';
import 'webhook_management_screen.dart';
import 'shared_projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GeminiService _gemini;
  final VoiceService _voice = VoiceService();
  int _selectedIndex = 0;
  final GlobalKey<ChatScreenState> chatKey = GlobalKey<ChatScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ContinuityService _continuity = ContinuityService();

  final List<_NavItem> _navItems = const [
    _NavItem('Chat', Icons.chat),
    _NavItem('Tasks', Icons.task_alt),
    _NavItem('Memory', Icons.memory),
    _NavItem('Android', Icons.phone_android),
    _NavItem('Files', Icons.folder),
    _NavItem('Docs', Icons.article),
    _NavItem('Browser', Icons.language),
    _NavItem('Calendar', Icons.calendar_today),
    _NavItem('Workflows', Icons.autorenew),
    _NavItem('Plugins', Icons.extension),
    _NavItem('Analytics', Icons.analytics),
    _NavItem('Code', Icons.code),
    _NavItem('Auto Agent', Icons.smart_toy),
    _NavItem('Settings', Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    final pluginService = context.read<PluginService>();
    final analyticsService = context.read<AnalyticsService>();
    final systemPromptService = context.read<SystemPromptService>();
    final plannerService = context.read<PlannerService>();
    _gemini = GeminiService(pluginService, analyticsService, systemPromptService, plannerService);
    context.read<MemoryService>().loadMessages();
    _setupWakeWord();
    _restoreLastSession();
  }

  void _restoreLastSession() async {
    final state = await _continuity.restoreState();
    if (state != null && state['selectedNavIndex'] != null) {
      if (mounted) {
        setState(() => _selectedIndex = state['selectedNavIndex'] as int);
      }
    }
  }

  void _onNavChanged(int index) {
    setState(() => _selectedIndex = index);
    _continuity.saveState(selectedNavIndex: index, activeChatScreen: _navItems[index].label);
  }

  void _setupWakeWord() {
    _voice.onWakeWordDetected = () async {
      if (!mounted) return;
      _onNavChanged(0);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final spoken = await _voice.listen(timeout: const Duration(seconds: 7));
      if (spoken != null && spoken.isNotEmpty && mounted) {
        chatKey.currentState?.sendVoiceCommand(spoken);
      }
    };
  }

  Widget _buildScreen() {
    if (_selectedIndex >= _navItems.length) _selectedIndex = 0;
    switch (_navItems[_selectedIndex].label) {
      case 'Chat': return ChatScreen(gemini: _gemini, voice: _voice, key: chatKey);
      case 'Tasks': return const TasksScreen();
      case 'Memory': return const MemoryScreen();
      case 'Android': return const AndroidScreen();
      case 'Files': return const FilesScreen();
      case 'Docs': return const DocumentsScreen();
      case 'Browser': return const BrowserScreen();
      case 'Calendar': return const CalendarScreen();
      case 'Workflows': return const WorkflowScreen();
      case 'Plugins': return const PluginsScreen();
      case 'Analytics': return const AnalyticsScreen();
      case 'Code': return const CodeExecutionScreen();
      case 'Auto Agent': return const AutonomousRunnerScreen();
      default: return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        if (deviceType == DeviceType.desktop) {
          return _buildDesktopLayout();
        } else if (deviceType == DeviceType.tablet) {
          return _buildTabletLayout();
        }
        return _buildPhoneLayout();
      },
    );
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          IconButton(
            icon: Icon(context.watch<VoiceService>().wakeWordActive ? Icons.mic : Icons.mic_none),
            onPressed: () {
              if (context.read<VoiceService>().wakeWordActive) {
                context.read<VoiceService>().stopWakeWordListening();
              } else {
                context.read<VoiceService>().startWakeWordListening();
              }
            },
          ),
        ],
      ),
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavChanged,
        destinations: _navItems.map((item) =>
          NavigationDestination(icon: Icon(item.icon), label: item.label)
        ).toList(),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          IconButton(
            icon: Icon(context.watch<VoiceService>().wakeWordActive ? Icons.mic : Icons.mic_none),
            onPressed: () {
              if (context.read<VoiceService>().wakeWordActive) {
                context.read<VoiceService>().stopWakeWordListening();
              } else {
                context.read<VoiceService>().startWakeWordListening();
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavChanged,
            labelType: NavigationRailLabelType.all,
            destinations: _navItems.map((item) =>
              NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              )
            ).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          IconButton(
            icon: Icon(context.watch<VoiceService>().wakeWordActive ? Icons.mic : Icons.mic_none),
            onPressed: () {
              if (context.read<VoiceService>().wakeWordActive) {
                context.read<VoiceService>().stopWakeWordListening();
              } else {
                context.read<VoiceService>().startWakeWordListening();
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListView(
              children: _navItems.map((item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: _navItems.indexOf(item) == _selectedIndex,
                onTap: () => _onNavChanged(_navItems.indexOf(item)),
              )).toList(),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
