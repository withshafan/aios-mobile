import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'planner_screen.dart';
import 'goal_screen.dart';
import 'knowledge_graph_screen.dart';
import 'plugin_marketplace_screen.dart';
import 'research_screen.dart';
import 'knowledge_base_screen.dart';
import 'approval_settings_screen.dart';
import 'digital_twin_screen.dart';

import 'cognitive/executive_dashboard.dart';
import 'cognitive/cognitive_state_screen.dart';
import 'cognitive/world_model_screen.dart';
import 'cognitive/life_timeline_screen.dart';
import 'cognitive/strategic_mission_screen.dart';
import 'cognitive/attention_screen.dart';
import 'cognitive/curiosity_screen.dart';
import 'cognitive/opportunities_screen.dart';
import 'cognitive/coach_screen.dart';
import 'cognitive/emotional_screen.dart';
import 'cognitive/trust_screen.dart';
import 'cognitive/reality_verification_screen.dart';
import 'cognitive/maintenance_screen.dart';
import 'cognitive/personality_settings_screen.dart';

import 'connected_services_screen.dart';
import 'unified_search_screen.dart';
import 'research_mission_screen.dart';

import 'llm_providers_screen.dart';
import 'agent_team_screen.dart';
import 'self_programming_screen.dart';
import 'ai_os_kernel_dashboard.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GeminiService _gemini;
  final VoiceService _voice = VoiceService();
  String _currentScreen = 'chat';
  final GlobalKey<ChatScreenState> chatKey = GlobalKey<ChatScreenState>();

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
  }

  void _setupWakeWord() {
    _voice.onWakeWordDetected = () async {
      if (!mounted) return;
      setState(() => _currentScreen = 'chat');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final spoken = await _voice.listen(timeout: const Duration(seconds: 7));
      if (spoken != null && spoken.isNotEmpty && mounted) {
        chatKey.currentState?.sendVoiceCommand(spoken);
      }
    };
  }

  Widget _buildBody() {
    switch (_currentScreen) {
      case 'chat': return ChatScreen(gemini: _gemini, voice: _voice, key: chatKey);
      case 'tasks': return const TasksScreen();
      case 'memory': return const MemoryScreen();
      case 'android': return const AndroidScreen();
      case 'files': return const FilesScreen();
      case 'docs': return const DocumentsScreen();
      case 'browser': return const BrowserScreen();
      case 'calendar': return const CalendarScreen();
      case 'workflows': return const WorkflowScreen();
      case 'planner': return const PlannerScreen();
      case 'plugins': return const PluginsScreen();
      case 'analytics': return const AnalyticsScreen();
      case 'goals': return const GoalScreen();
      case 'knowledge_graph': return const KnowledgeGraphScreen();
      case 'marketplace': return const PluginMarketplaceScreen();
      case 'research': return const ResearchScreen();
      case 'knowledge_base': return const KnowledgeBaseScreen();
      case 'approval': return const ApprovalSettingsScreen();
      case 'digital_twin': return const DigitalTwinScreen();
      
      case 'executive_dashboard': return const ExecutiveDashboard();
      case 'cognitive_state': return CognitiveStateScreen();
      case 'world_model': return WorldModelScreen();
      case 'life_timeline': return LifeTimelineScreen();
      case 'strategic_missions': return StrategicMissionScreen();
      case 'attention': return AttentionScreen();
      case 'curiosity': return CuriosityScreen();
      case 'opportunities': return OpportunitiesScreen();
      case 'coach': return CoachScreen();
      case 'emotional': return EmotionalScreen();
      case 'trust': return TrustScreen();
      case 'reality_verification': return RealityVerificationScreen();
      case 'maintenance': return MaintenanceScreen();
      case 'personality_settings': return PersonalitySettingsScreen();

      default: return const SettingsScreen();
    }
  }
  
  void _navigate(BuildContext context, String screenId) {
    setState(() => _currentScreen = screenId);
    Navigator.pop(context);
  }

  Widget _drawerItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceService>();
    final browserService = context.watch<BrowserService>();

    if (browserService.navigateToBrowser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentScreen = 'browser');
          browserService.didNavigate();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('AIOS – ${_currentScreen.replaceAll('_', ' ').toUpperCase()}'),
        actions: [
          IconButton(
            icon: Icon(
              voice.wakeWordActive ? Icons.mic : Icons.mic_none,
              color: voice.wakeWordActive ? Colors.red : null,
            ),
            tooltip: voice.wakeWordActive ? 'Listening for "Hey AIOS"' : 'Enable Wake Word',
            onPressed: () {
              if (voice.wakeWordActive) {
                voice.stopWakeWordListening();
              } else {
                voice.startWakeWordListening();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('AIOS AURA Cognitive OS', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _drawerItem(context, 'Chat', Icons.chat, () => _navigate(context, 'chat')),
            _drawerItem(context, 'Executive Dashboard', Icons.dashboard, () => _navigate(context, 'executive_dashboard')),
            const Divider(),
            _drawerItem(context, 'Cognitive State', Icons.psychology, () => _navigate(context, 'cognitive_state')),
            _drawerItem(context, 'World Model', Icons.public, () => _navigate(context, 'world_model')),
            _drawerItem(context, 'Life Timeline', Icons.timeline, () => _navigate(context, 'life_timeline')),
            _drawerItem(context, 'Strategic Missions', Icons.flag, () => _navigate(context, 'strategic_missions')),
            const Divider(),
            _drawerItem(context, 'Attention Center', Icons.notifications_active, () => _navigate(context, 'attention')),
            _drawerItem(context, 'Curiosity Feed', Icons.explore, () => _navigate(context, 'curiosity')),
            _drawerItem(context, 'Opportunities', Icons.lightbulb, () => _navigate(context, 'opportunities')),
            const Divider(),
            _drawerItem(context, 'Personal Coach', Icons.trending_up, () => _navigate(context, 'coach')),
            _drawerItem(context, 'Emotional Context', Icons.sentiment_satisfied, () => _navigate(context, 'emotional')),
            _drawerItem(context, 'Trust & Reality', Icons.verified, () => _navigate(context, 'trust')),
            _drawerItem(context, 'Reality Verification', Icons.fact_check, () => _navigate(context, 'reality_verification')),
            const Divider(),
            _drawerItem(context, 'System Maintenance', Icons.build, () => _navigate(context, 'maintenance')),
            _drawerItem(context, 'Personality Mode', Icons.settings_accessibility, () => _navigate(context, 'personality_settings')),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connected Services'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectedServicesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Unified Search'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UnifiedSearchScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Digital Twin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalTwinScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Autonomous Research'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResearchMissionScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('Multi-LLM Orchestrator'),
              onTap: () {
                Navigator.pop(context);
                // Show a simple info or test screen (optional)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Multi-LLM orchestrator active in background')));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.hub),
              title: const Text('LLM Providers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LLMProvidersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('AI Team'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentTeamScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Self-Programming'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfProgrammingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('AI OS Kernel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AIOSKernelDashboard()));
              },
            ),
            const Divider(),
            // Legacy tools
            _drawerItem(context, 'Tasks', Icons.task_alt, () => _navigate(context, 'tasks')),
            _drawerItem(context, 'Planner', Icons.account_tree, () => _navigate(context, 'planner')),
            _drawerItem(context, 'Android', Icons.phone_android, () => _navigate(context, 'android')),
            _drawerItem(context, 'Files', Icons.folder, () => _navigate(context, 'files')),
            _drawerItem(context, 'Docs', Icons.article, () => _navigate(context, 'docs')),
            _drawerItem(context, 'Browser', Icons.language, () => _navigate(context, 'browser')),
            _drawerItem(context, 'Calendar', Icons.calendar_today, () => _navigate(context, 'calendar')),
            _drawerItem(context, 'Workflows', Icons.autorenew, () => _navigate(context, 'workflows')),
            _drawerItem(context, 'Plugins', Icons.extension, () => _navigate(context, 'plugins')),
            _drawerItem(context, 'Analytics', Icons.analytics, () => _navigate(context, 'analytics')),
            const Divider(),
            _drawerItem(context, 'Goals', Icons.flag, () => _navigate(context, 'goals')),
            _drawerItem(context, 'Knowledge Graph', Icons.share, () => _navigate(context, 'knowledge_graph')),
            _drawerItem(context, 'Plugin Marketplace', Icons.store, () => _navigate(context, 'marketplace')),
            _drawerItem(context, 'Research Mode', Icons.science, () => _navigate(context, 'research')),
            _drawerItem(context, 'Knowledge Base', Icons.search, () => _navigate(context, 'knowledge_base')),
            _drawerItem(context, 'Approval Level', Icons.security, () => _navigate(context, 'approval')),
            _drawerItem(context, 'Digital Twin', Icons.person, () => _navigate(context, 'digital_twin')),
            const Divider(),
            _drawerItem(context, 'Settings', Icons.settings, () => _navigate(context, 'settings')),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
