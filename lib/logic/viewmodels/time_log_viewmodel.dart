import 'package:flutter/foundation.dart';
import '../../data/models/time_log.dart';
import '../../data/repositories/time_log_repository.dart';

class TimeLogViewModel extends ChangeNotifier {
  final TimeLogRepository _repository;

  List<TimeLog> _logs = [];
  bool isLoading = false;
  String? errorMessage;

  TimeLogViewModel(this._repository) {
    loadLogs();
  }

  List<TimeLog> get logs => List.unmodifiable(_logs);

  Future<void> loadLogs() async {
    isLoading = true;
    notifyListeners();

    try {
      _logs = _repository.getAllLogs();
    } catch (e) {
      errorMessage = 'Failed to load logs: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLog(TimeLog log) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.saveLog(log);
      _logs = _repository.getAllLogs(); // Refresh logs
    } catch (e) {
      errorMessage = 'Failed to save log: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLog(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteLog(id);
      _logs = _repository.getAllLogs();
    } catch (e) {
      errorMessage = 'Failed to delete log: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Duration calculateDailyTotal(TimeLog log) {
    Duration total = Duration.zero;

    if (log.amIn != null && log.amOut != null) {
      total += log.amOut!.difference(log.amIn!);
    }
    if (log.pmIn != null && log.pmOut != null) {
      total += log.pmOut!.difference(log.pmIn!);
    }
    if (log.otIn != null && log.otOut != null) {
      total += log.otOut!.difference(log.otIn!);
    }
    
    return total;
  }

  Duration calculateMonthlyTotal(int year, int month) {
    Duration total = Duration.zero;
    for (var log in _logs) {
      if (log.date.year == year && log.date.month == month) {
        total += calculateDailyTotal(log);
      }
    }
    return total;
  }
}
