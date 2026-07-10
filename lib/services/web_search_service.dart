import 'dart:convert';
import 'package:http/http.dart' as http;

class WebSearchService {
  // Uses DuckDuckGo Instant Answer API (free, no key)
  Future<List<Map<String, String>>> search(String query) async {
    final url = Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, String>> results = [];
        if (data['AbstractText'] != null && data['AbstractText'].toString().isNotEmpty) {
          results.add({'title': data['AbstractSource'] ?? 'DuckDuckGo', 'snippet': data['AbstractText']});
        }
        for (var topic in data['RelatedTopics'] ?? []) {
          if (topic is Map && topic['Text'] != null) {
            results.add({'title': topic['FirstURL'] ?? '', 'snippet': topic['Text']});
          }
        }
        return results.take(5).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }
}
