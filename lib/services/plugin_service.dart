import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';
import '../models/plugin_info.dart';

class PluginService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _httpClient = http.Client();

  List<PluginInfo> _plugins = [];
  List<PluginInfo> get plugins => _plugins;

  // Predefined plugins (seeded on first load)
  static const List<Map<String, dynamic>> builtInPlugins = [
    {
      'name': 'Joke Generator',
      'description': 'Tells a random joke',
      'functionName': 'get_joke',
      'parameters': {},
    },
    {
      'name': 'Calculator',
      'description': 'Evaluate a mathematical expression',
      'functionName': 'calculate',
      'parameters': {
        'expression': 'string',
      },
    },
    {
      'name': 'Random Fact',
      'description': 'Get a random fact',
      'functionName': 'get_fact',
      'parameters': {},
    },
  ];

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  PluginService() {
    loadPlugins();
  }

  void loadPlugins() {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('plugins')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Seed built-in plugins
        await _seedPlugins();
      } else {
        _plugins = snapshot.docs
            .map((doc) => PluginInfo.fromFirestore(doc.data(), doc.id))
            .toList();
        notifyListeners();
      }
    });
  }

  Future<void> _seedPlugins() async {
    final batch = _firestore.batch();
    for (var pluginData in builtInPlugins) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('plugins')
          .doc(); // auto ID
      final info = PluginInfo(
        id: docRef.id,
        name: pluginData['name'] as String,
        description: pluginData['description'] as String,
        functionName: pluginData['functionName'] as String,
        parameters: Map<String, dynamic>.from(pluginData['parameters'] as Map),
        isEnabled: false,
      );
      batch.set(docRef, info.toFirestore());
    }
    await batch.commit();
  }

  Future<void> togglePlugin(String id, bool currentState) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plugins')
        .doc(id)
        .update({'isEnabled': !currentState});
  }

  /// Execute a plugin function and return the result string
  Future<String> executeFunction(String functionName, Map<String, dynamic>? args) async {
    switch (functionName) {
      case 'get_joke':
        final response = await _httpClient.get(
          Uri.parse('https://v2.jokeapi.dev/joke/Any?format=txt'),
        );
        if (response.statusCode == 200) {
          return response.body;
        }
        return 'Could not fetch a joke.';
      case 'calculate':
        final expr = args?['expression'] as String? ?? '';
        try {
          final parsed = Parser().parse(expr);
          final result = ContextModel().evaluate(parsed);
          return 'Result: $result';
        } catch (e) {
          return 'Invalid expression.';
        }
      case 'get_fact':
        final response = await _httpClient.get(
          Uri.parse('http://numbersapi.com/random?json'),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['text'] as String;
        }
        return 'Could not fetch a fact.';
      default:
        return 'Unknown function.';
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
