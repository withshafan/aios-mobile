import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigitalTwinScreen extends StatelessWidget {
  const DigitalTwinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('digital_twin')
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data?.data() == null) {
          return const Center(child: Text('Learning your patterns...'));
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Working Hours: ${data['workingHours'] ?? 'Not yet learned'}'),
            Text('Coding Style: ${data['codingStyle'] ?? 'Unknown'}'),
            Text('Frequent Apps: ${data['frequentApps']?.join(', ') ?? 'None'}'),
            // Add more learned attributes
          ],
        );
      },
    );
  }
}
