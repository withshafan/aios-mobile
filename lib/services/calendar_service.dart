import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'audit_service.dart';

class CalendarService {
  /// Get authenticated CalendarApi client using the signed-in Google account
  Future<cal.CalendarApi?> getCalendarApi(GoogleSignInAccount googleUser) async {
    final authClient = await googleUser.authenticatedClient();
    return cal.CalendarApi(authClient);
  }

  /// List upcoming events from primary calendar
  Future<List<cal.Event>> listUpcomingEvents(GoogleSignInAccount googleUser) async {
    final api = await getCalendarApi(googleUser);
    if (api == null) return [];
    final now = DateTime.now().toUtc();
    final events = await api.events.list(
      'primary',
      timeMin: now,
      maxResults: 20,
      singleEvents: true,
      orderBy: 'startTime',
    );
    return events.items ?? [];
  }

  /// Create a new event
  Future<cal.Event> createEvent(
    GoogleSignInAccount googleUser, {
    required String summary,
    required DateTime start,
    required DateTime end,
    String? description,
  }) async {
    final api = await getCalendarApi(googleUser);
    if (api == null) throw Exception('Calendar API not available');

    final event = cal.Event()
      ..summary = summary
      ..start = cal.EventDateTime(dateTime: start)
      ..end = cal.EventDateTime(dateTime: end);
    if (description != null) {
      event.description = description;
    }
    
    final createdEvent = await api.events.insert(event, 'primary');
    
    final audit = AuditService();
    await audit.log(
      agent: 'calendar',
      action: 'create_event',
      tier: 'irreversible',
      details: {'summary': summary, 'start': start.toIso8601String()},
    );
    
    return createdEvent;
  }

  /// Delete an event
  Future<void> deleteEvent(GoogleSignInAccount googleUser, String eventId) async {
    final api = await getCalendarApi(googleUser);
    if (api == null) return;
    await api.events.delete('primary', eventId);
  }
}
