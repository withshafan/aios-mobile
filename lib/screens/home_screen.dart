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
      default: return const SettingsScreen();
    }
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
              child: Text('AIOS AURA', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: const Icon(Icons.chat), title: const Text('Chat'), onTap: () { setState(() => _currentScreen = 'chat'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.task_alt), title: const Text('Tasks'), onTap: () { setState(() => _currentScreen = 'tasks'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.memory), title: const Text('Memory'), onTap: () { setState(() => _currentScreen = 'memory'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.phone_android), title: const Text('Android'), onTap: () { setState(() => _currentScreen = 'android'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.folder), title: const Text('Files'), onTap: () { setState(() => _currentScreen = 'files'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.article), title: const Text('Docs'), onTap: () { setState(() => _currentScreen = 'docs'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.language), title: const Text('Browser'), onTap: () { setState(() => _currentScreen = 'browser'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Calendar'), onTap: () { setState(() => _currentScreen = 'calendar'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.autorenew), title: const Text('Workflows'), onTap: () { setState(() => _currentScreen = 'workflows'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.account_tree), title: const Text('Planner'), onTap: () { setState(() => _currentScreen = 'planner'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.extension), title: const Text('Plugins'), onTap: () { setState(() => _currentScreen = 'plugins'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.analytics), title: const Text('Analytics'), onTap: () { setState(() => _currentScreen = 'analytics'); Navigator.pop(context); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.flag), title: const Text('Goals'), onTap: () { setState(() => _currentScreen = 'goals'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.share), title: const Text('Knowledge Graph'), onTap: () { setState(() => _currentScreen = 'knowledge_graph'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.store), title: const Text('Plugin Marketplace'), onTap: () { setState(() => _currentScreen = 'marketplace'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.science), title: const Text('Research Mode'), onTap: () { setState(() => _currentScreen = 'research'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.search), title: const Text('Knowledge Base'), onTap: () { setState(() => _currentScreen = 'knowledge_base'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.security), title: const Text('Approval Level'), onTap: () { setState(() => _currentScreen = 'approval'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.person), title: const Text('Digital Twin'), onTap: () { setState(() => _currentScreen = 'digital_twin'); Navigator.pop(context); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () { setState(() => _currentScreen = 'settings'); Navigator.pop(context); }),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
