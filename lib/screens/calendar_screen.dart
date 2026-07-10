import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final auth = context.read<AuthService>();
    final googleUser = auth.googleUser;
    if (googleUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final events = await _calendarService.listUpcomingEvents(googleUser);
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  Future<void> _createManualEvent() async {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd)'),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result != true) return;
    final googleUser = context.read<AuthService>().googleUser;
    if (googleUser == null) return;
    final dateStr = dateController.text.trim();
    final timeStr = timeController.text.trim();
    final start = DateTime.parse('${dateStr}T$timeStr:00');
    final end = start.add(const Duration(hours: 1));
    await _calendarService.createEvent(
      googleUser,
      summary: titleController.text,
      start: start,
      end: end,
    );
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Create Event'),
          onPressed: _createManualEvent,
        ),
        Expanded(
          child: _events.isEmpty
              ? const Center(child: Text('No upcoming events'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (_, i) {
                    final event = _events[i];
                    final start = event.start?.dateTime ?? event.start?.date;
                    final startStr = start != null
                        ? DateFormat('MMM dd, yyyy – HH:mm').format(start)
                        : 'All day';
                    return ListTile(
                      title: Text(event.summary ?? 'No title'),
                      subtitle: Text(startStr),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final googleUser = context.read<AuthService>().googleUser;
                          if (googleUser != null) {
                            await _calendarService.deleteEvent(googleUser, event.id!);
                            _loadEvents();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
