import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/llm_provider.dart';

class MultiLLMService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<LLMProvider>> get providers => _db
          .collection('users')
          .doc(uid)
          .collection('llm_providers')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => LLMProvider.fromMap(d.data()))
              .toList());

  Future<void> saveProvider(LLMProvider provider) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('llm_providers')
        .doc(provider.id)
        .set(provider.toMap());
  }

  Future<void> deleteProvider(String id) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('llm_providers')
        .doc(id)
        .delete();
  }

  /// Simple routing based on complexity (keyword detection)
  Future<String> routePrompt(String prompt) async {
    final providersSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('llm_providers')
        .where('isEnabled', isEqualTo: true)
        .orderBy('priority')
        .get();
    if (providersSnap.docs.isEmpty) return 'No enabled providers.';
    final provider = LLMProvider.fromMap(providersSnap.docs.first.data());
    // Simulate API call to different provider
    try {
      final response = await http.post(
        Uri.parse('${provider.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${provider.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'default',
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response.';
      }
      return 'Error from ${provider.name}';
    } catch (e) {
      return 'Failed to reach ${provider.name}';
    }
  }

  // Seed with default providers
  static Future<void> seedDefaults(FirebaseFirestore db, String uid) async {
    final snap = await db.collection('users').doc(uid).collection('llm_providers').get();
    if (snap.docs.isNotEmpty) return;
    final defaults = [
      LLMProvider(id: 'gemini', name: 'Google Gemini', baseUrl: 'https://generativelanguage.googleapis.com', isEnabled: true, priority: 1),
      LLMProvider(id: 'openai', name: 'OpenAI', baseUrl: 'https://api.openai.com/v1', priority: 2),
      LLMProvider(id: 'claude', name: 'Anthropic Claude', baseUrl: 'https://api.anthropic.com/v1', priority: 3),
      LLMProvider(id: 'ollama', name: 'Ollama (Local)', baseUrl: 'http://localhost:11434/v1', priority: 4),
    ];
    for (var p in defaults) {
      await db.collection('users').doc(uid).collection('llm_providers').doc(p.id).set(p.toMap());
    }
  }
}
