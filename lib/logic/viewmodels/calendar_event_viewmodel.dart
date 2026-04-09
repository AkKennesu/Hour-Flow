import 'package:flutter/material.dart';
import '../../data/models/calendar_event.dart';
import '../../data/services/database_service.dart';
import '../../services/notification_service.dart';

class CalendarEventViewModel extends ChangeNotifier {
  final DatabaseService _dbConfig;
  List<CalendarEvent> _events = [];

  List<CalendarEvent> get events => _events;

  CalendarEventViewModel(this._dbConfig) {
    _loadEvents();
  }

  void _loadEvents() {
    _events = _dbConfig.eventBox.values.toList();
    notifyListeners();
  }

  Future<void> saveEvent(CalendarEvent event) async {
    await _dbConfig.eventBox.put(event.id, event);
    _loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _dbConfig.eventBox.delete(id);
    _loadEvents();
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) => DateUtils.isSameDay(event.date, day)).toList();
  }
}
