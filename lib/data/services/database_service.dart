import 'package:hive_flutter/hive_flutter.dart';
import '../models/time_log.dart';
import '../models/calendar_event.dart';

class DatabaseService {
  Box<TimeLog>? _logBox;
  Box<CalendarEvent>? _eventBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TimeLogAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }
  }

  /// Opens user-specific boxes. This should be called whenever the user ID changes.
  Future<void> openUserBoxes(String userId) async {
    // Close existing boxes if any
    await closeUserBoxes();
    
    _logBox = await Hive.openBox<TimeLog>('timelogs_$userId');
    _eventBox = await Hive.openBox<CalendarEvent>('calendarEvents_$userId');
  }

  Future<void> closeUserBoxes() async {
    await _logBox?.close();
    await _eventBox?.close();
    _logBox = null;
    _eventBox = null;
  }

  Box<TimeLog> get logBox {
    if (_logBox == null) throw Exception("Database not initialized for user. Call openUserBoxes first.");
    return _logBox!;
  }

  Box<CalendarEvent> get eventBox {
    if (_eventBox == null) throw Exception("Database not initialized for user. Call openUserBoxes first.");
    return _eventBox!;
  }

  Future<void> saveLog(TimeLog log) async {
    await logBox.put(log.id, log);
  }

  Future<void> deleteLog(String id) async {
    await logBox.delete(id);
  }

  List<TimeLog> getAllLogs() {
    return logBox.values.toList();
  }

  TimeLog? getLog(String id) {
    return logBox.get(id);
  }
}
