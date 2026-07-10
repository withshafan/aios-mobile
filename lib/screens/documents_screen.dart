import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../services/document_service.dart';
import 'package:intl/intl.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final GeminiService _gemini = GeminiService();
  String _generatedContent = '';
  String _title = '';
  bool _isGenerating = false;

  Future<void> _generate() async {
    final topic = _promptController.text.trim();
    if (topic.isEmpty) return;
    setState(() => _isGenerating = true);
    _title = topic.length > 50 ? '${topic.substring(0, 50)}...' : topic;
    try {
      final response = await _gemini.sendMessage(
        'Write a professional document about: $topic. Return only the plain text, no markdown.',
        null, // no history needed
      );
      _generatedContent = response.text;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved as $type in Downloads')),
      );
      await docService.openFile(filePath);
    } catch (e) {
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
    return Column(
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
                child: Text(_generatedContent),
              ),
            ),
          ),
        ],
        if (docs.isNotEmpty) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  ),
                  title: Text(doc['title']),
                  subtitle: Text(dateStr),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
