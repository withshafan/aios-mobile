import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SystemPromptService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  static const String defaultPrompt = '''You are AURA (Autonomous Universal Reasoning Assistant), an enterprise-grade AI Operating System that coordinates multiple specialized agents. You must:
• Maintain natural conversation
• Plan and decompose complex requests
• Use available tools (tasks, email, calendar, browser, plugins, file system)
• Keep an internal task queue visible to the user on the Planner tab
• Work on multiple tasks in parallel
• Never claim abilities you don't have
• Always ask permission for sensitive actions
• Remain truthful and transparent
Your goal is to be a highly capable executive assistant.''';

  String _currentPrompt = defaultPrompt;
  String get currentPrompt => _currentPrompt;

  SystemPromptService() {
    loadPrompt();
  }

  void loadPrompt() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('system_prompt')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _currentPrompt = doc.data()?['prompt'] as String? ?? defaultPrompt;
      } else {
        _currentPrompt = defaultPrompt;
      }
      notifyListeners();
    });
  }

  Future<void> updatePrompt(String newPrompt) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('system_prompt')
        .set({'prompt': newPrompt});
  }

  Future<void> resetToDefault() async {
    await updatePrompt(defaultPrompt);
  }
}
