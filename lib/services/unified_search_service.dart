import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnifiedSearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> search(String query) async {
    List<Map<String, dynamic>> results = [];
    final lower = query.toLowerCase();

    // Search local documents
    final docs = await _db.collection('users').doc(uid).collection('documents').get();
    for (var doc in docs.docs) {
      final data = doc.data();
      if (data['title'].toString().toLowerCase().contains(lower)) {
        results.add({...data, 'id': doc.id, 'source': 'Documents'});
      }
    }

    // Search chat messages
    final chats = await _db.collection('users').doc(uid).collection('chats').orderBy('timestamp', descending: true).limit(50).get();
    for (var chat in chats.docs) {
      final data = chat.data();
      if (data['content'].toString().toLowerCase().contains(lower)) {
        results.add({...data, 'id': chat.id, 'source': 'Chat'});
      }
    }

    // Search tasks
    final tasks = await _db.collection('users').doc(uid).collection('tasks').get();
    for (var task in tasks.docs) {
      final data = task.data();
      if (data['title'].toString().toLowerCase().contains(lower)) {
        results.add({...data, 'id': task.id, 'source': 'Tasks'});
      }
    }

    // Search connected knowledge items (if any)
    final knowledge = await _db.collection('users').doc(uid).collection('knowledge_items').where('title', isGreaterThanOrEqualTo: query).where('title', isLessThanOrEqualTo: '$query\uf8ff').get();
    for (var item in knowledge.docs) {
      results.add({...item.data(), 'id': item.id});
    }

    return results;
  }
}
