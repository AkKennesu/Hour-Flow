// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeLogAdapter extends TypeAdapter<TimeLog> {
  @override
  final int typeId = 0;

  @override
  TimeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      amIn: fields[2] as DateTime?,
      amOut: fields[3] as DateTime?,
      pmIn: fields[4] as DateTime?,
      pmOut: fields[5] as DateTime?,
      otIn: fields[8] as DateTime?,
      otOut: fields[9] as DateTime?,
      tasks: fields[6] as String?,
      isSynchronized: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimeLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.amIn)
      ..writeByte(3)
      ..write(obj.amOut)
      ..writeByte(4)
      ..write(obj.pmIn)
      ..writeByte(5)
      ..write(obj.pmOut)
      ..writeByte(6)
      ..write(obj.tasks)
      ..writeByte(7)
      ..write(obj.isSynchronized)
      ..writeByte(8)
      ..write(obj.otIn)
      ..writeByte(9)
      ..write(obj.otOut);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
