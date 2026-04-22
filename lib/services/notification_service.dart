import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/calendar_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Android Boot Receiver setup
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    // Request exact alarm permission automatically in Android 13+
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> scheduleEventNotifications(CalendarEvent event) async {
    // 1. Notification 1 day before (Near)
    final nearDate = event.date.subtract(const Duration(days: 1));
    final nearDateAt9AM = DateTime(nearDate.year, nearDate.month, nearDate.day, 9, 0);
    
    if (nearDateAt9AM.isAfter(DateTime.now())) {
      await _zonedSchedule(
        id: event.id.hashCode,
        title: 'Upcoming Event: ${event.title}',
        body: 'Tomorrow: ${event.description}',
        scheduledDate: nearDateAt9AM,
      );
    }

    // 2. Notification on the exact day (Today)
    final todayDateAt8AM = DateTime(event.date.year, event.date.month, event.date.day, 8, 0);
    if (todayDateAt8AM.isAfter(DateTime.now())) {
      await _zonedSchedule(
        id: event.id.hashCode + 1,
        title: 'Today: ${event.title}',
        body: event.description.isNotEmpty ? event.description : 'Don\'t forget your event today!',
        scheduledDate: todayDateAt8AM,
      );
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_events',
          'Calendar Events',
          channelDescription: 'Notifications for upcoming events.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotifications(String eventId) async {
    await _notificationsPlugin.cancel(id: eventId.hashCode);
    await _notificationsPlugin.cancel(id: eventId.hashCode + 1);
  }
}
