import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/memory_service.dart';
import '../services/task_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/document_service.dart';
import 'chat_screen.dart';
import 'memory_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'android_screen.dart';
import 'files_screen.dart';
import 'documents_screen.dart';
import 'workflow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GeminiService _gemini = GeminiService();
  final VoiceService _voice = VoiceService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<MemoryService>().loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(gemini: _gemini, voice: _voice),
      const TasksScreen(),
      const MemoryScreen(),
      const AndroidScreen(),
      const FilesScreen(),
      const DocumentsScreen(),
      const WorkflowScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIOS Mobile'),
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
          NavigationDestination(icon: Icon(Icons.autorenew), label: 'Workflows'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
