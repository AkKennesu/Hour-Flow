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
}
