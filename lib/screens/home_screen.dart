import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../utils/responsive.dart';
import '../services/auth_service.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/simple_ai_service.dart';
import '../services/document_service.dart';
import '../services/plugin_service.dart';
import '../services/browser_service.dart';
import '../services/analytics_service.dart';
import 'chat_screen_nova.dart';
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
  late final SimpleAiService _aiService;
  int _selectedIndex = 0;

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
    _aiService = context.read<SimpleAiService>();
    context.read<MemoryService>().loadMessages();
  }

  Widget _buildScreen(int index) {
    // Keep state alive for ChatScreen by using IndexedStack 
    // or just switch screens as before. Since ChatProvider initializes and holds history,
    // switching tabs will lose local ChatProvider state.
    // If you want chat state to persist across tab switches, we can use IndexedStack,
    // but a standard switch was used originally. 
    switch (index) {
      case 0: return NovaChatScreen(aiService: _aiService);
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
      appBar: _selectedIndex == 0 ? null : AppBar(
        title: Text(_navItems[_selectedIndex].label),
      ),
      body: Material(
        type: MaterialType.transparency,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            NovaChatScreen(aiService: _aiService),
            const DashboardScreen(),
            const TasksScreen(),
            const WorkflowScreen(),
            const MoreScreen(),
          ],
        ),
      ),
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
      appBar: _selectedIndex == 0 ? null : AppBar(
        title: Text(_navItems[_selectedIndex].label),
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
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  NovaChatScreen(aiService: _aiService),
                  const DashboardScreen(),
                  const TasksScreen(),
                  const WorkflowScreen(),
                  const MoreScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: _selectedIndex == 0 ? null : AppBar(
        title: Text(_navItems[_selectedIndex].label),
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
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  NovaChatScreen(aiService: _aiService),
                  const DashboardScreen(),
                  const TasksScreen(),
                  const WorkflowScreen(),
                  const MoreScreen(),
                ],
              ),
            ),
          ),
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

