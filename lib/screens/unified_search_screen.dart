import 'package:flutter/material.dart';
import '../theme/tokens.dart';
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
            padding: const EdgeInsets.all(space4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search chats, docs, tasks, emails...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusSm),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _search,
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Search across your entire knowledge base'))
                : ListView.builder(
                    padding: const EdgeInsets.all(space4),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final item = _results[i];
                      return Card(
                        color: AppColors.surfaceRaised,
                        margin: const EdgeInsets.only(bottom: space2),
                        child: ListTile(
                          title: Text(item['title'] ?? item['content']?.substring(0, 60) ?? 'Untitled'),
                          subtitle: Text('Source: ${item['source'] ?? 'Unknown'}'),
                          trailing: Icon(Icons.open_in_new, color: AppColors.accentViolet),
                          onTap: () {
                            // could navigate to detail view
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
