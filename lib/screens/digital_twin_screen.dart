import 'package:flutter/material.dart';
import '../services/digital_twin_service.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen> {
  final _service = DigitalTwinService();
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _service.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Twin')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (ctx, snap) {
          final data = snap.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Working Hours: ${data['workingHours'] ?? 'Not set'}'),
              const SizedBox(height: 10),
              Text('Coding Style: ${data['codingStyle'] ?? 'Unknown'}'),
              const SizedBox(height: 10),
              Text('Favorite Apps: ${(data['favoriteApps'] as List?)?.join(', ') ?? 'None'}'),
              // add more fields
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _service.updateProfile({'workingHours': '9-5'});
                  setState(() {
                    _profileFuture = _service.getProfile();
                  });
                },
                child: const Text('Update Working Hours (Demo)'),
              ),
            ],
          );
        },
      ),
    );
  }
}
