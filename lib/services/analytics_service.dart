import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  // Today's data
  int _messagesToday = 0;
  int _tokensInput = 0;
  int _tokensOutput = 0;
  int get messagesToday => _messagesToday;
  int get tokensToday => _tokensInput + _tokensOutput;

  // Agent usage counts (accumulated all time, but we'll show today's counts)
  Map<String, int> _agentCountsToday = {};
  Map<String, int> get agentCountsToday => _agentCountsToday;

  AnalyticsService() {
    debugPrint('AnalyticsService constructor START');
    loadTodayData();
  }

  void loadTodayData() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _firestore
        .collection('users')
        .doc(userId)
        .collection('analytics')
        .doc(todayStr)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _messagesToday = data['messages'] ?? 0;
        _tokensInput = data['tokensInput'] ?? 0;
        _tokensOutput = data['tokensOutput'] ?? 0;
        final agentMap = data['agents'] as Map<String, dynamic>? ?? {};
        _agentCountsToday = agentMap.map((k, v) => MapEntry(k, v as int));
      } else {
        // Reset for new day
        _messagesToday = 0;
        _tokensInput = 0;
        _tokensOutput = 0;
        _agentCountsToday = {};
      }
      notifyListeners();
    });
  }

  Future<void> logMessage(int inputTokens, int outputTokens, {String? agentName}) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('analytics')
        .doc(todayStr);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int messages = 0;
      int tokensIn = 0;
      int tokensOut = 0;
      Map<String, dynamic> agents = {};
      if (snapshot.exists) {
        final data = snapshot.data()!;
        messages = data['messages'] ?? 0;
        tokensIn = data['tokensInput'] ?? 0;
        tokensOut = data['tokensOutput'] ?? 0;
        agents = Map<String, dynamic>.from(data['agents'] ?? {});
      }
      messages += 1;
      tokensIn += inputTokens;
      tokensOut += outputTokens;
      if (agentName != null) {
        agents[agentName] = (agents[agentName] ?? 0) + 1;
      }
      transaction.set(docRef, {
        'messages': messages,
        'tokensInput': tokensIn,
        'tokensOutput': tokensOut,
        'agents': agents,
        'date': todayStr,
      });
    });
  }

  /// Approximate tokens from text: ~4 characters per token
  int estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}

