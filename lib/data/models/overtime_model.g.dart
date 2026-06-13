// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overtime_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OvertimeModelAdapter extends TypeAdapter<OvertimeModel> {
  @override
  final typeId = 9;

  @override
  OvertimeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OvertimeModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      siteId: fields[2] as String,
      date: fields[3] as DateTime,
      startTime: fields[4] as String,
      endTime: fields[5] as String,
      reason: fields[6] as String,
      status: fields[7] as OvertimeStatus,
      approvedBy: fields[8] as String?,
      instructedBy: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OvertimeModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.siteId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.approvedBy)
      ..writeByte(9)
      ..write(obj.instructedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OvertimeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
