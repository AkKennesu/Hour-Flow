import '../../services/notification_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/connectivity_service.dart';
import '../../data/services/database_service.dart';
import '../../data/models/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarEventViewModel extends ChangeNotifier {
  final DatabaseService _dbConfig;
  final CloudSyncService _syncService;
  final ConnectivityService _connectivityService;
  List<CalendarEvent> _events = [];

  List<CalendarEvent> get events => _events;

  CalendarEventViewModel(this._dbConfig, this._syncService, this._connectivityService) {
    loadEvents();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        _syncAllPending();
      }
    });
  }

  Future<void> _syncAllPending() async {
    await _syncService.syncAllPendingCalendarEvents(_events, (updatedEvent) async {
      await _dbConfig.eventBox.put(updatedEvent.id, updatedEvent);
      loadEvents();
    });
  }

  void loadEvents() {
    _events = _dbConfig.eventBox.values.toList();
    notifyListeners();
  }

  Future<void> saveEvent(CalendarEvent event) async {
    await _dbConfig.eventBox.put(event.id, event);
    await NotificationService().scheduleEventNotifications(event);
    loadEvents();
    
    // Cloud sync
    try {
      await _syncService.syncCalendarEvent(event);
    } catch (e) {
      debugPrint("Cloud sync failed for event: $e");
    }
  }

  Future<void> deleteEvent(String id) async {
    await _dbConfig.eventBox.delete(id);
    await NotificationService().cancelNotifications(id);
    loadEvents();

    // Cloud delete
    try {
      await _syncService.deleteCalendarEvent(id);
    } catch (e) {
      debugPrint("Cloud delete failed for event: $e");
    }
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) => DateUtils.isSameDay(event.date, day)).toList();
  }
}
