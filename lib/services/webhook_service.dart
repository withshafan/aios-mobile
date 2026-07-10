import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebhookService {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addWebhook(String event, String url) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('webhooks')
        .add({'event': event, 'url': url});
  }

  Future<void> triggerEvent(String event, Map<String, dynamic> data) async {
    final snaps = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('webhooks')
        .where('event', isEqualTo: event)
        .get();
    for (var doc in snaps.docs) {
      final url = doc.data()['url'] as String;
      try {
        await http.post(Uri.parse(url), body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        // Log failure if needed
      }
    }
  }

  Stream<QuerySnapshot> get webhooks => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('webhooks')
      .snapshots();

  Future<void> deleteWebhook(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('webhooks')
        .doc(id)
        .delete();
  }
}
