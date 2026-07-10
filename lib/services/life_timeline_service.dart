import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LifeTimelineEvent {
  String id;
  String title;
  String category; // 'education','project','job', etc.
  DateTime date;
  String description;

  LifeTimelineEvent({required this.id, required this.title, required this.category, required this.date, this.description = ''});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'description': description,
      };

  factory LifeTimelineEvent.fromMap(Map<String, dynamic> map) => LifeTimelineEvent(
        id: map['id'],
        title: map['title'],
        category: map['category'],
        date: DateTime.parse(map['date']),
        description: map['description'] ?? '',
      );
}

class LifeTimelineService extends ChangeNotifier {
  LifeTimelineService() {
    debugPrint('LifeTimelineService constructor START');
    debugPrint('LifeTimelineService constructor END');
  }
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<LifeTimelineEvent>> get events => _db
          .collection('users')
          .doc(uid)
          .collection('timeline')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => LifeTimelineEvent.fromMap(d.data()))
              .toList());

  Future<void> addEvent(LifeTimelineEvent event) async {
    await _db.collection('users').doc(uid).collection('timeline').doc(event.id).set(event.toMap());
  }
}
