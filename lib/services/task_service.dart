import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

class TaskService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  List<AiosTask> _tasks = [];
  List<AiosTask> get tasks => _tasks;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  TaskService() {
    tz_data.initializeTimeZones();
    _initNotifications();
    loadTasks();
  }

  void _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _notifications.initialize(init);
  }

  void loadTasks() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .listen((snapshot) {
      _tasks = snapshot.docs
          .map((doc) => AiosTask.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addTask(AiosTask task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .add(task.toFirestore());
    _scheduleNotification(task);
  }

  Future<void> toggleComplete(String taskId, bool current) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !current});
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  void _scheduleNotification(AiosTask task) async {
    // Schedule a notification at dueDate using local timezone
    final location = tz.local;
    final scheduledDate = tz.TZDateTime.from(task.dueDate, location);

    // Only schedule if the date is in the future
    if (scheduledDate.isAfter(tz.TZDateTime.now(location))) {
      const androidDetails = AndroidNotificationDetails(
        'aios_tasks',
        'Task Reminders',
        channelDescription: 'Reminders for your AIOS tasks',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await _notifications.zonedSchedule(
        task.id.hashCode, // unique id based on task id
        'Reminder: ${task.title}',
        task.description ?? 'Your task is due!',
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> createFromCommand(String title, DateTime dueDate, [String? description]) async {
    final task = AiosTask(
      id: '',
      title: title,
      description: description,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await addTask(task);
  }
}
