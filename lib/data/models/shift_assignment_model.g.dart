// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_assignment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftAssignmentModelAdapter extends TypeAdapter<ShiftAssignmentModel> {
  @override
  final typeId = 5;

  @override
  ShiftAssignmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftAssignmentModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      shiftId: fields[2] as String,
      siteId: fields[3] as String,
      date: fields[4] as DateTime,
      assignedBy: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ShiftAssignmentModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.shiftId)
      ..writeByte(3)
      ..write(obj.siteId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.assignedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAssignmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
