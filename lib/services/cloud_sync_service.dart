import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/time_log.dart';
import '../data/models/calendar_event.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> syncTimeLog(TimeLog log) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('timeLogs')
        .doc(log.id)
        .set(log.toMap());
  }

  Future<void> syncCalendarEvent(CalendarEvent event) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarEvents')
        .doc(event.id)
        .set(event.toMap());
  }

  Future<void> deleteTimeLog(String logId) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('timeLogs')
        .doc(logId)
        .delete();
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarEvents')
        .doc(eventId)
        .delete();
  }

  // Potential for full sync on login
  Future<List<TimeLog>> fetchAllTimeLogs() async {
    final uid = _userId;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timeLogs')
        .get();

    return snapshot.docs
        .map((doc) => TimeLog.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<CalendarEvent>> fetchAllCalendarEvents() async {
    final uid = _userId;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarEvents')
        .get();

    return snapshot.docs
        .map((doc) => CalendarEvent.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> syncAllPendingTimeLogs(List<TimeLog> logs, Function(TimeLog) onSynced) async {
    final uid = _userId;
    if (uid == null) return;

    for (var log in logs) {
      if (!log.isSynchronized) {
        try {
          await syncTimeLog(log);
          onSynced(log.copyWith(isSynchronized: true));
        } catch (e) {
          print("Error syncing log ${log.id}: $e");
        }
      }
    }
  }

  Future<void> syncAllPendingCalendarEvents(List<CalendarEvent> events, Function(CalendarEvent) onSynced) async {
    final uid = _userId;
    if (uid == null) return;

    for (var event in events) {
      if (!event.isSynchronized) {
        try {
          await syncCalendarEvent(event);
          onSynced(event.copyWith(isSynchronized: true));
        } catch (e) {
          print("Error syncing event ${event.id}: $e");
        }
      }
    }
  }
}
