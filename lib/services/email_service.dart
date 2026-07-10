import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  /// Save SMTP configuration to Firestore
  Future<void> saveConfig({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    await _firestore.collection('users').doc(userId).collection('settings').doc('email').set({
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    });
  }

  /// Get SMTP config from Firestore
  Future<Map<String, dynamic>?> getConfig() async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('email')
        .get();
    if (doc.exists) return doc.data();
    return null;
  }

  /// Send an email using saved SMTP config
  Future<String> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final config = await getConfig();
    if (config == null) {
      throw Exception('Email not configured. Please set up SMTP in Settings.');
    }
    final smtpServer = SmtpServer(
      config['host'] as String,
      port: config['port'] as int,
      username: config['username'] as String,
      password: config['password'] as String,
    );

    final message = Message()
      ..from = Address(config['username'] as String)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      return 'Email sent to $to';
    } on MailerException catch (e) {
      return 'Failed to send email: ${e.toString()}';
    }
  }
}
