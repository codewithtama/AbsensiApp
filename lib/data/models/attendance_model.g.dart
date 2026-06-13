// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceModelAdapter extends TypeAdapter<AttendanceModel> {
  @override
  final typeId = 3;

  @override
  AttendanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      siteId: fields[2] as String,
      shiftId: fields[3] as String?,
      status: fields[4] as AttendanceStatus,
      timestamp: fields[5] as DateTime,
      latitude: (fields[6] as num).toDouble(),
      longitude: (fields[7] as num).toDouble(),
      deviceName: fields[8] as String?,
      deviceOs: fields[9] as String?,
      networkType: fields[10] as String?,
      isLate: fields[11] as bool?,
      isEarlyOut: fields[12] as bool?,
      delayMinutes: (fields[13] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.siteId)
      ..writeByte(3)
      ..write(obj.shiftId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.deviceName)
      ..writeByte(9)
      ..write(obj.deviceOs)
      ..writeByte(10)
      ..write(obj.networkType)
      ..writeByte(11)
      ..write(obj.isLate)
      ..writeByte(12)
      ..write(obj.isEarlyOut)
      ..writeByte(13)
      ..write(obj.delayMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
