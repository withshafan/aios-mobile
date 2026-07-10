import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ApprovalMode { observe, assist, autonomous }

class ApprovalSettingsScreen extends StatefulWidget {
  const ApprovalSettingsScreen({super.key});

  @override
  State<ApprovalSettingsScreen> createState() => _ApprovalSettingsScreenState();
}

class _ApprovalSettingsScreenState extends State<ApprovalSettingsScreen> {
  ApprovalMode _mode = ApprovalMode.assist;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  void _loadMode() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('approval')
        .get();
    if (doc.exists && doc.data()?['mode'] != null) {
      setState(() {
        _mode = ApprovalMode.values[doc.data()!['mode'] as int];
      });
    }
  }

  void _setMode(ApprovalMode mode) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('approval')
        .set({'mode': mode.index});
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: ApprovalMode.values.map((mode) {
          return RadioListTile<ApprovalMode>(
            title: Text(mode.name.toUpperCase()),
            subtitle: Text(_getDescription(mode)),
            value: mode,
            groupValue: _mode,
            onChanged: (val) => _setMode(val!),
          );
        }).toList(),
      ),
    );
  }

  String _getDescription(ApprovalMode mode) {
    switch (mode) {
      case ApprovalMode.observe:
        return 'Only suggest actions, never execute.';
      case ApprovalMode.assist:
        return 'Ask before important actions.';
      case ApprovalMode.autonomous:
        return 'Automatically execute low-risk tasks.';
    }
  }
}
