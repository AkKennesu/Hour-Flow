import 'package:flutter/foundation.dart';
import '../../data/models/time_log.dart';
import '../../data/repositories/time_log_repository.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/connectivity_service.dart';

class TimeLogViewModel extends ChangeNotifier {
  final TimeLogRepository _repository;
  final CloudSyncService _syncService;
  final ConnectivityService _connectivityService;

  List<TimeLog> _logs = [];
  bool isLoading = false;
  String? errorMessage;

  TimeLogViewModel(this._repository, this._syncService, this._connectivityService) {
    loadLogs();
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
    await _syncService.syncAllPendingTimeLogs(_logs, (updatedLog) async {
      await _repository.saveLog(updatedLog);
      _logs = _repository.getAllLogs();
      notifyListeners();
    });
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
      
      // Attempt cloud sync after local save
      try {
        await _syncService.syncTimeLog(log);
        // If successful, we could mark as synced in Hive too
        final updatedLog = log.copyWith(isSynchronized: true);
        await _repository.saveLog(updatedLog);
        _logs = _repository.getAllLogs();
      } catch (e) {
        debugPrint("Cloud sync failed: $e");
      }
    } catch (e) {
      errorMessage = 'Failed to save log: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLogs(List<TimeLog> logs) async {
    isLoading = true;
    notifyListeners();

    try {
      for (var log in logs) {
        await _repository.saveLog(log);
      }
      _logs = _repository.getAllLogs();
      
      // Attempt cloud sync for each in background to avoid blocking
      for (var log in logs) {
        _syncService.syncTimeLog(log).catchError((e) => debugPrint("Batch cloud sync failed: $e"));
      }
    } catch (e) {
      errorMessage = 'Failed to save batch logs: $e';
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
      
      // Attempt cloud deletion
      try {
        await _syncService.deleteTimeLog(id);
      } catch (e) {
        debugPrint("Cloud delete failed: $e");
      }
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
