import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../services/document_service.dart';
import '../services/ai_chat_service.dart';
import '../services/plugin_service.dart';
import '../services/analytics_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _promptController = TextEditingController();
  late final AiChatService _aiService;
  String _generatedContent = '';
  String _title = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Get AI service from provider
    _aiService = context.read<AiChatService>();
  }

  Future<void> _generate() async {
    final topic = _promptController.text.trim();
    if (topic.isEmpty) return;
    setState(() => _isGenerating = true);
    _title = topic.length > 50 ? '${topic.substring(0, 50)}...' : topic;
    try {
      final response = await _aiService.sendMessage(
        userMessage: 'Write a professional document about: $topic. Return only the plain text, no markdown.',
      );
      _generatedContent = response;
    } catch (e) {
      _generatedContent = 'Failed to generate content. Try again.';
    }
    setState(() => _isGenerating = false);
  }

  Future<void> _saveAs(String type) async {
    final docService = context.read<DocumentService>();
    try {
      late String filePath;
      if (type == 'pdf') {
        filePath = await docService.generatePdf(_title, _generatedContent);
      } else {
        filePath = await docService.generateDocx(_title, _generatedContent);
      }
      await docService.saveToHistory(_title, type, filePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved as $type in Downloads')),
      );
      await docService.openFile(filePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<DocumentService>().documents;

    // Return a Scaffold to ensure Material context for all children
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a topic (e.g., "Project Plan")',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                const SizedBox(width: 8),
                _isGenerating
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _generate,
                        child: const Text('Generate'),
                      ),
              ],
            ),
          ),
          if (_generatedContent.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Save PDF'),
                    onPressed: () => _saveAs('pdf'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.article),
                    label: const Text('Save Word'),
                    onPressed: () => _saveAs('docx'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(_generatedContent, style: const TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            ),
          ],
          if (docs.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final dateStr = DateFormat('MMM dd, yyyy – hh:mm').format(
                    DateTime.parse(doc['createdAt']),
                  );
                  return ListTile(
                    leading: Icon(
                      doc['type'] == 'pdf' ? Icons.picture_as_pdf : Icons.article,
                      color: AppColors.accentViolet,
                    ),
                    title: Text(doc['title'], style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(dateStr, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.accentCritical),
                      onPressed: () => context.read<DocumentService>().deleteDocument(doc['id']),
                    ),
                    onTap: () {
                      context.read<DocumentService>().openFile(doc['filePath']);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
