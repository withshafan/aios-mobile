import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/memory_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import 'chat_screen.dart';

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
      const Center(child: Text('Settings')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIOS Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: context.read<AuthService>().signOut,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
