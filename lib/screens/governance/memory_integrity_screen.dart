import 'package:flutter/material.dart';
import '../../services/memory_integrity_service.dart';

class MemoryIntegrityScreen extends StatefulWidget {
  const MemoryIntegrityScreen({super.key});

  @override
  State<MemoryIntegrityScreen> createState() => _MemoryIntegrityScreenState();
}

class _MemoryIntegrityScreenState extends State<MemoryIntegrityScreen> {
  List<Map<String, dynamic>> _conflicts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _findConflicts();
  }

  Future<void> _findConflicts() async {
    setState(() => _loading = true);
    final conflicts = await MemoryIntegrityService().findConflicts();
    setState(() {
      _conflicts = conflicts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Integrity Check')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? const Center(child: Text('No contradictions found.'))
              : ListView.builder(
                  itemCount: _conflicts.length,
                  itemBuilder: (_, i) {
                    final pair = _conflicts[i];
                    return Card(
                      child: ExpansionTile(
                        title: const Text('Possible Contradiction'),
                        children: [
                          ListTile(
                            title: Text(pair['first']['content']),
                            subtitle: const Text('Earlier message'),
                          ),
                          ListTile(
                            title: Text(pair['second']['content']),
                            subtitle: const Text('Later message'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.archive),
                            label: const Text('Archive older one'),
                            onPressed: () {
                              // Archive logic (simplified)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Archived')));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _findConflicts,
      ),
    );
  }
}
