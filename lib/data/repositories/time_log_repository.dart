import '../models/time_log.dart';
import '../services/database_service.dart';

class TimeLogRepository {
  final DatabaseService _dbService;

  TimeLogRepository(this._dbService);

  Future<void> saveLog(TimeLog log) async {
    await _dbService.saveLog(log);
    // In a real app with backend:
    // try to save remotely. If fail, set isSynchronized = false. 
  }

  Future<void> deleteLog(String id) async {
    await _dbService.deleteLog(id);
  }

  List<TimeLog> getAllLogs() {
    return _dbService.getAllLogs()..sort((a, b) => b.date.compareTo(a.date));
  }

  TimeLog? getLogById(String id) {
    return _dbService.getLog(id);
  }
}
