import 'package:flutter/material.dart';
import '../services/unified_search_service.dart';

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchService = UnifiedSearchService();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _searchService.search(query);
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unified Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search across all your knowledge...',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _search(_searchCtrl.text)),
              ),
              onSubmitted: _search,
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final item = _results[i];
                return ListTile(
                  title: Text(item['title'] ?? item['content']?.substring(0, 50) ?? 'No title'),
                  subtitle: Text('Source: ${item['source'] ?? 'Unknown'}'),
                  onTap: () {
                    // open detail
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening...')));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
