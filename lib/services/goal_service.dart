import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/goal.dart';

class GoalService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  GoalService() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .listen((snap) {
      _goals = snap.docs.map((d) => Goal.fromFirestore(d.data(), d.id)).toList();
      notifyListeners();
    });
  }

  Future<void> addGoal(Goal goal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .set(goal.toFirestore());
  }

  Future<void> updateGoal(Goal goal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .update(goal.toFirestore());
  }

  Future<void> deleteGoal(String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(id)
        .delete();
  }

  void updateSubtask(String goalId, int index, bool completed) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.subtasks[index].isCompleted = completed;
    goal.progress = goal.subtasks.isEmpty
        ? 0.0
        : goal.subtasks.where((s) => s.isCompleted).length /
            goal.subtasks.length;
    updateGoal(goal);
  }
}
