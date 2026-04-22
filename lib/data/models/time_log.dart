import 'package:hive/hive.dart';

part 'time_log.g.dart';

@HiveType(typeId: 0)
class TimeLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final DateTime? amIn;

  @HiveField(3)
  final DateTime? amOut;

  @HiveField(4)
  final DateTime? pmIn;

  @HiveField(5)
  final DateTime? pmOut;

  @HiveField(6)
  final String? tasks;

  @HiveField(7)
  bool isSynchronized;

  @HiveField(8)
  final DateTime? otIn;

  @HiveField(9)
  final DateTime? otOut;

  TimeLog({
    required this.id,
    required this.date,
    this.amIn,
    this.amOut,
    this.pmIn,
    this.pmOut,
    this.otIn,
    this.otOut,
    this.tasks,
    this.isSynchronized = false,
  });

  TimeLog copyWith({
    String? id,
    DateTime? date,
    DateTime? amIn,
    DateTime? amOut,
    DateTime? pmIn,
    DateTime? pmOut,
    DateTime? otIn,
    DateTime? otOut,
    String? tasks,
    bool? isSynchronized,
  }) {
    return TimeLog(
      id: id ?? this.id,
      date: date ?? this.date,
      amIn: amIn ?? this.amIn,
      amOut: amOut ?? this.amOut,
      pmIn: pmIn ?? this.pmIn,
      pmOut: pmOut ?? this.pmOut,
      otIn: otIn ?? this.otIn,
      otOut: otOut ?? this.otOut,
      tasks: tasks ?? this.tasks,
      isSynchronized: isSynchronized ?? this.isSynchronized,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amIn': amIn,
      'amOut': amOut,
      'pmIn': pmIn,
      'pmOut': pmOut,
      'otIn': otIn,
      'otOut': otOut,
      'tasks': tasks,
    };
  }

  factory TimeLog.fromMap(String id, Map<String, dynamic> map) {
    return TimeLog(
      id: id,
      date: (map['date'] as dynamic).toDate(),
      amIn: (map['amIn'] as dynamic)?.toDate(),
      amOut: (map['amOut'] as dynamic)?.toDate(),
      pmIn: (map['pmIn'] as dynamic)?.toDate(),
      pmOut: (map['pmOut'] as dynamic)?.toDate(),
      otIn: (map['otIn'] as dynamic)?.toDate(),
      otOut: (map['otOut'] as dynamic)?.toDate(),
      tasks: map['tasks'],
      isSynchronized: true,
    );
  }
}
