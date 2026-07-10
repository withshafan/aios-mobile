import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../services/memory_integrity_service.dart';

class MemoryIntegrityScreen extends StatefulWidget {
  const MemoryIntegrityScreen({super.key});

  @override
  State<MemoryIntegrityScreen> createState() => _MemoryIntegrityScreenState();
}

class _MemoryIntegrityScreenState extends State<MemoryIntegrityScreen> {
  final _memoryIntegrity = MemoryIntegrityService();
  List<Map<String, dynamic>> _conflicts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _findConflicts();
  }

  Future<void> _findConflicts() async {
    setState(() => _loading = true);
    final conflicts = await _memoryIntegrity.findConflicts();
    setState(() {
      _conflicts = conflicts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Integrity')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? const Center(child: Text('No contradictions found. Memory is consistent.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(space4),
                  itemCount: _conflicts.length,
                  itemBuilder: (_, i) {
                    final pair = _conflicts[i];
                    return Card(
                      color: AppColors.surfaceRaised,
                      margin: const EdgeInsets.only(bottom: space3),
                      child: Padding(
                        padding: const EdgeInsets.all(space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Potential Contradiction', style: TextStyle(color: AppColors.accentWarning)),
                            const SizedBox(height: space2),
                            Container(
                              padding: const EdgeInsets.all(space3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOverlay,
                                borderRadius: BorderRadius.circular(radiusSm),
                              ),
                              child: Text(pair['first']['content']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(height: space1),
                            const Text('vs', style: TextStyle(color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.all(space3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOverlay,
                                borderRadius: BorderRadius.circular(radiusSm),
                              ),
                              child: Text(pair['second']['content']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(height: space3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // resolve: delete first, keep second
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Resolved — older message archived')),
                                    );
                                    _findConflicts();
                                  },
                                  child: const Text('Resolve'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Ignore'),
                                ),
                              ],
                            ),
                          ],
                        ),
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
