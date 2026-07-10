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

  @override
  void initState() {
    super.initState();
    final pluginService = context.read<PluginService>();
    final analyticsService = context.read<AnalyticsService>();
    _gemini = GeminiService(pluginService, analyticsService);
    context.read<MemoryService>().loadMessages();
    _setupWakeWord();
  }

  void _setupWakeWord() {
    _voice.onWakeWordDetected = () async {
      if (!mounted) return;
      setState(() => _selectedIndex = 0);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final spoken = await _voice.listen(timeout: const Duration(seconds: 7));
      if (spoken != null && spoken.isNotEmpty && mounted) {
        chatKey.currentState?.sendVoiceCommand(spoken);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceService>();
    final browserService = context.watch<BrowserService>();

    if (browserService.navigateToBrowser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = 6); // Browser index
          browserService.didNavigate();
        }
      });
    }

    final screens = [
      ChatScreen(gemini: _gemini, voice: _voice, key: chatKey),
      const TasksScreen(),
      const MemoryScreen(),
      const AndroidScreen(),
      const FilesScreen(),
      const DocumentsScreen(),
      const BrowserScreen(),
      const CalendarScreen(),
      const WorkflowScreen(),
      const PluginsScreen(),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIOS Mobile'),
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
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.memory), label: 'Memory'),
          NavigationDestination(icon: Icon(Icons.phone_android), label: 'Android'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Files'),
          NavigationDestination(icon: Icon(Icons.article), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.language), label: 'Browser'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.autorenew), label: 'Workflows'),
          NavigationDestination(icon: Icon(Icons.extension), label: 'Plugins'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
