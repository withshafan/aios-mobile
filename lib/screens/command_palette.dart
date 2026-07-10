import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../widgets/glass_card.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_PaletteItem> _results = [];
  int _selectedIndex = 0;

  static final List<_PaletteItem> _allItems = [
    _PaletteItem('Chat', 'Start a new conversation', Icons.chat, '/chat'),
    _PaletteItem('Dashboard', 'View your overview', Icons.dashboard, '/dashboard'),
    _PaletteItem('Tasks', 'Manage tasks', Icons.task_alt, '/tasks'),
    _PaletteItem('Memory', 'Browse memories', Icons.memory, '/memory'),
    _PaletteItem('Android Device', 'Control your phone', Icons.phone_android, '/android'),
    _PaletteItem('Files', 'Browse files', Icons.folder, '/files'),
    _PaletteItem('Documents', 'Generate documents', Icons.article, '/docs'),
    _PaletteItem('Browser', 'Open web browser', Icons.language, '/browser'),
    _PaletteItem('Calendar', 'View calendar', Icons.calendar_today, '/calendar'),
    _PaletteItem('Workflows', 'Automation rules', Icons.autorenew, '/workflows'),
    _PaletteItem('Plugins', 'Manage plugins', Icons.extension, '/plugins'),
    _PaletteItem('Analytics', 'Usage statistics', Icons.analytics, '/analytics'),
    _PaletteItem('Settings', 'Configure app', Icons.settings, '/settings'),
    _PaletteItem('New Task', 'Create a new task', Icons.add_task, '/new_task'),
    _PaletteItem('Send Email', 'Compose email', Icons.email, '/email'),
    _PaletteItem('Generate PDF', 'Create a PDF document', Icons.picture_as_pdf, '/generate_pdf'),
    _PaletteItem('Ask Agent', 'Send a prompt to Aura', Icons.auto_awesome, '/ask'),
  ];

  @override
  void initState() {
    super.initState();
    _results = _allItems;
    _focusNode.requestFocus();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = _allItems;
      } else {
        _results = _allItems
            .where((item) =>
                item.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  void _execute(_PaletteItem item) {
    Navigator.pop(context); // close palette
    // Use navigator key to navigate
    final navigator = Navigator.of(context, rootNavigator: true);
    // For simplicity, we push named routes (you'll need to set up routes)
    switch (item.route) {
      case '/chat': navigator.pushNamed('/chat'); break;
      case '/dashboard': navigator.pushNamed('/dashboard'); break;
      // ... other routes
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${item.label}...')),
        );
    }
  }

  void _moveSelection(int delta) {
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, _results.length - 1);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveSelection(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveSelection(-1),
      },
      child: GlassCard(
        width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(space3),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search commands...',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceRaised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  if (_results.isNotEmpty) _execute(_results[_selectedIndex]);
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.borderHairline),
            // Results list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final isSelected = index == _selectedIndex;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.accentViolet.withOpacity(0.2),
                    leading: Icon(item.icon, color: isSelected ? AppColors.accentViolet : AppColors.textSecondary),
                    title: Text(item.label, style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(item.description, style: const TextStyle(color: AppColors.textSecondary)),
                    onTap: () => _execute(item),
                  );
                },
              ),
            ),
            // Keyboard hint footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space2),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.keyboard, size: 14, color: AppColors.textDisabled),
                  SizedBox(width: space2),
                  Text('↑↓ navigate · Enter select · Esc close', style: TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteItem {
  final String label;
  final String description;
  final IconData icon;
  final String route;

  const _PaletteItem(this.label, this.description, this.icon, this.route);
}
