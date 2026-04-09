import 'package:flutter/material.dart';
import '../data/models/calendar_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // No external packages required.
    // In-app notifications are handled natively by Dashboard Check!
  }

  void checkAndShowInAppNotifications(BuildContext context, List<CalendarEvent> allEvents) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // Find events happening today or tomorrow.
    final upcomingEvents = allEvents.where((event) {
      final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDay.isAtSameMomentAs(todayStart) || eventDay.isAtSameMomentAs(tomorrowStart);
    }).toList();

    if (upcomingEvents.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var event in upcomingEvents) {
        final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
        final isToday = eventDay.isAtSameMomentAs(todayStart);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isToday ? Colors.redAccent.withOpacity(0.9) : Colors.purpleAccent.withOpacity(0.9),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(isToday ? Icons.warning_amber_rounded : Icons.event, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'TODAY: ${event.title}' : 'TOMORROW: ${event.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (event.description.isNotEmpty)
                        Text(event.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }
}
