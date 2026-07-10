import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class MemoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  void loadMessages() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> sendMessage(String content, {bool isUser = true, String? audioUrl}) async {
    final message = ChatMessage(
      id: '',
      content: content,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .add(message.toFirestore());
  }

  Future<void> clearMemory() async {
    final batch = _firestore.batch();
    final docs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .get();
    for (var doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _messages = [];
    notifyListeners();
  }
}
