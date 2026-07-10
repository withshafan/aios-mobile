import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/workflow.dart';
import 'task_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WorkflowService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final TaskService _taskService; // injected

  List<Workflow> _workflows = [];
  List<Workflow> get workflows => _workflows;
  Timer? _evaluationTimer;
  Set<String> _executedToday = {}; // prevent duplicate executions

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  WorkflowService(this._taskService) {
    debugPrint('WorkflowService constructor START');
    _initNotifications();
    loadWorkflows();
    startEvaluation();
    debugPrint('WorkflowService constructor END');
  }

  void _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _notifications.initialize(init);
  }

  void loadWorkflows() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('workflows')
        .snapshots()
        .listen((snapshot) {
      _workflows = snapshot.docs
          .map((doc) => Workflow.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addWorkflow(Workflow workflow) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workflows')
        .doc(workflow.id)
        .set(workflow.toFirestore());
  }

  Future<void> updateWorkflow(Workflow workflow) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workflows')
        .doc(workflow.id)
        .update(workflow.toFirestore());
  }

  Future<void> deleteWorkflow(String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workflows')
        .doc(id)
        .delete();
  }

  Future<void> toggleActive(String id, bool current) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workflows')
        .doc(id)
        .update({'isActive': !current});
  }

  void startEvaluation() {
    // Evaluate every 60 seconds
    _evaluationTimer = Timer.periodic(const Duration(seconds: 60), (_) => evaluateAll());
  }

  void evaluateAll() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    _executedToday.removeWhere((key) => !key.startsWith(todayStr));

    for (final workflow in _workflows) {
      if (!workflow.isActive) continue;
      if (workflow.triggerType == 'time') {
        final targetTime = workflow.triggerData; // e.g., "09:00"
        final currentTime = DateFormat('HH:mm').format(now);
        final executionKey = '$todayStr-${workflow.id}';
        if (currentTime == targetTime && !_executedToday.contains(executionKey)) {
          _executedToday.add(executionKey);
          _executeAction(workflow);
        }
      }
    }
  }

  void _executeAction(Workflow workflow) {
    if (workflow.actionType == 'create_task') {
      _taskService.createFromCommand(
        workflow.actionData,
        DateTime.now().add(const Duration(hours: 1)), // due in 1 hour as default
      );
    } else if (workflow.actionType == 'notification') {
      const androidDetails = AndroidNotificationDetails(
        'workflow_channel',
        'Workflow Notifications',
        channelDescription: 'Notifications from your workflows',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      _notifications.show(
        workflow.id.hashCode, // unique id
        workflow.name,
        workflow.actionData,
        details,
      );
    }
  }

  @override
  void dispose() {
    _evaluationTimer?.cancel();
    super.dispose();
  }
}

