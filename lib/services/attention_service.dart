import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttentionItem {
  String id;
  String title;
  String type; // 'notification', 'reminder', 'alert'
  int urgency; // 1-10
  int importance; // 1-10
  DateTime timestamp;
  bool isRead;

  AttentionItem({required this.id, required this.title, this.type = 'notification', this.urgency = 5, this.importance = 5, required this.timestamp, this.isRead = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'urgency': urgency,
        'importance': importance,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory AttentionItem.fromMap(Map<String, dynamic> map) => AttentionItem(
        id: map['id'],
        title: map['title'],
        type: map['type'] ?? 'notification',
        urgency: map['urgency'] ?? 5,
        importance: map['importance'] ?? 5,
        timestamp: DateTime.parse(map['timestamp']),
        isRead: map['isRead'] ?? false,
      );
}

class AttentionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<AttentionItem>> get items => _db
          .collection('users')
          .doc(uid)
          .collection('attention')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AttentionItem.fromMap(d.data()))
              .toList());

  Future<void> addItem(AttentionItem item) async {
    await _db.collection('users').doc(uid).collection('attention').doc(item.id).set(item.toMap());
  }

  Future<void> markRead(String id) async {
    await _db.collection('users').doc(uid).collection('attention').doc(id).update({'isRead': true});
  }
}
