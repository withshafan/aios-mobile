import 'package:flutter/material.dart';

class ActionTiersScreen extends StatelessWidget {
  const ActionTiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action Tiering Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tierCard('Read‑Only', Icons.remove_red_eye, Colors.green,
              'No confirmation needed. Examples: open file, view calendar, read email.'),
          _tierCard('Reversible', Icons.undo, Colors.orange,
              'Soft confirmation with undo window. Examples: move file, create task.'),
          _tierCard('Irreversible / High‑Stakes', Icons.warning, Colors.red,
              'Explicit confirmation required. Examples: send email, delete file, publish code.'),
        ],
      ),
    );
  }

  Widget _tierCard(String title, IconData icon, Color color, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(desc),
      ),
    );
  }
}
