import 'package:hive_flutter/hive_flutter.dart';
import '../models/time_log.dart';
import '../models/calendar_event.dart';

class DatabaseService {
  static const String logBoxName = 'timelogs';
  static const String eventBoxName = 'calendarEvents';
  late Box<TimeLog> _logBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TimeLogAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }

    _logBox = await Hive.openBox<TimeLog>(logBoxName);
    await Hive.openBox<CalendarEvent>(eventBoxName);
  }

  Box<TimeLog> get logBox => _logBox;
  Box<CalendarEvent> get eventBox => Hive.box<CalendarEvent>(eventBoxName);

  Future<void> saveLog(TimeLog log) async {
    await _logBox.put(log.id, log);
  }

  Future<void> deleteLog(String id) async {
    await _logBox.delete(id);
  }

  List<TimeLog> getAllLogs() {
    return _logBox.values.toList();
  }

  TimeLog? getLog(String id) {
    return _logBox.get(id);
  }
}
