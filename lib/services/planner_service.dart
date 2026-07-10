import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class PlannerService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> get tasks => _tasks;

  PlannerService() {
    loadTasks();
  }

  void loadTasks() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('plan_tasks')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      notifyListeners();
    });
  }

  Future<void> addTask(String description) async {
    final id = const Uuid().v4();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plan_tasks')
        .doc(id)
        .set({
      'description': description,
      'status': 'pending', // pending, in_progress, completed, failed
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plan_tasks')
        .doc(taskId)
        .update({'status': newStatus});
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plan_tasks')
        .doc(taskId)
        .delete();
  }
}
