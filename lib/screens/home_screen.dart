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
import 'more_screen.dart';
import 'dashboard_screen.dart';

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

  final List<_NavDestination> _navItems = const [
    _NavDestination('Chat', Icons.chat),
    _NavDestination('Dashboard', Icons.dashboard),
    _NavDestination('Workspace', Icons.workspaces),
    _NavDestination('Automation', Icons.smart_toy),
    _NavDestination('More', Icons.grid_view),
  ];

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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return ChatScreen(gemini: _gemini, voice: _voice, key: chatKey);
      case 1: return const DashboardScreen();
      case 2: return const TasksScreen();
      case 3: return const WorkflowScreen();
      case 4: return const MoreScreen();
      default: return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (context, deviceType) {
      if (deviceType == DeviceType.desktop) {
        return _buildDesktopLayout();
      } else if (deviceType == DeviceType.tablet) {
        return _buildTabletLayout();
      }
      return _buildPhoneLayout();
    });
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
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
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems.map((item) =>
          NavigationDestination(icon: Icon(item.icon), label: item.label),
        ).toList(),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
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
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: _navItems.map((item) =>
              NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
            ).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildScreen(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
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
          SizedBox(
            width: 260,
            child: Material(
              color: AppColors.surfaceBase,
              child: ListView(
                children: _navItems.map((item) {
                  final i = _navItems.indexOf(item);
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: i == _selectedIndex,
                    selectedTileColor: AppColors.accentViolet.withOpacity(0.2),
                    onTap: () => setState(() => _selectedIndex = i),
                  );
                }).toList(),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildScreen(_selectedIndex)),
        ],
      ),
    );
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  const _NavDestination(this.label, this.icon);
}
