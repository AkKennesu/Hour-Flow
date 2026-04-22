import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 1)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final bool hasNotifiedNear;

  @HiveField(5)
  final bool hasNotifiedToday;

  @HiveField(6)
  final bool isSynchronized;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.description = '',
    this.hasNotifiedNear = false,
    this.hasNotifiedToday = false,
    this.isSynchronized = false,
  });

  CalendarEvent copyWith({
    String? title,
    String? description,
    bool? hasNotifiedNear,
    bool? hasNotifiedToday,
    bool? isSynchronized,
  }) {
    return CalendarEvent(
      id: id,
      date: date,
      title: title ?? this.title,
      description: description ?? this.description,
      hasNotifiedNear: hasNotifiedNear ?? this.hasNotifiedNear,
      hasNotifiedToday: hasNotifiedToday ?? this.hasNotifiedToday,
      isSynchronized: isSynchronized ?? this.isSynchronized,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'description': description,
      'hasNotifiedNear': hasNotifiedNear,
      'hasNotifiedToday': hasNotifiedToday,
    };
  }

  factory CalendarEvent.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEvent(
      id: id,
      date: (map['date'] as dynamic).toDate(),
      title: map['title'],
      description: map['description'] ?? '',
      hasNotifiedNear: map['hasNotifiedNear'] ?? false,
      hasNotifiedToday: map['hasNotifiedToday'] ?? false,
      isSynchronized: true,
    );
  }
}
