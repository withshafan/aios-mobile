import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/continuity_service.dart';
import '../theme/tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ContinuityService _continuityService = ContinuityService();
  late Future<Map<String, dynamic>?> _lastStateFuture;

  @override
  void initState() {
    super.initState();
    _lastStateFuture = _continuityService.getLastState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 80, color: AppColors.accentViolet),
              const SizedBox(height: space5),
              const Text('AURA AIOS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: space7),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: auth.signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: space7),
              FutureBuilder<Map<String, dynamic>?>(
                future: _lastStateFuture,
                builder: (context, snap) {
                  if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                  final data = snap.data!;
                  final deviceName = data['deviceName'] as String? ?? 'Unknown device';
                  final lastActive = data['lastActive'] as Timestamp?;
                  final timeAgo = lastActive != null
                      ? _timeAgo(lastActive.toDate())
                      : 'recently';
                  return Column(
                    children: [
                      Text('Last active on $deviceName $timeAgo',
                          style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: space3),
                      OutlinedButton(
                        onPressed: () {
                          // Continue as same user (already signed in)
                        },
                        child: const Text('Continue session'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
