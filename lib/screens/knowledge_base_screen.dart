import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  void _search(String query) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Search in documents, tasks, calendar events, etc.
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('documents')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    // ... similarly search chats, tasks
    setState(() {
      _results = docSnap.docs.map((d) => d.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search your knowledge base...',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(_results[i]['title'] ?? 'No title'),
              subtitle: Text(_results[i]['type'] ?? ''),
            ),
          ),
        ),
      ],
    );
  }
}
