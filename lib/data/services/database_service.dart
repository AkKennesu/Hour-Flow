import 'package:hive_flutter/hive_flutter.dart';
import '../models/time_log.dart';

class DatabaseService {
  static const String _timeBoxName = 'timeLogs';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TimeLogAdapter());
    }
    await Hive.openBox<TimeLog>(_timeBoxName);
  }

  Box<TimeLog> get _box => Hive.box<TimeLog>(_timeBoxName);

  Future<void> saveLog(TimeLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> deleteLog(String id) async {
    await _box.delete(id);
  }

  List<TimeLog> getAllLogs() {
    return _box.values.toList();
  }

  TimeLog? getLog(String id) {
    return _box.get(id);
  }
}
