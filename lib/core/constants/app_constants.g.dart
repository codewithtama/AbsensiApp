// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_constants.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final typeId = 6;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.karyawan;
      case 1:
        return UserRole.leader;
      case 2:
        return UserRole.supervisor;
      case 3:
        return UserRole.manager;
      case 4:
        return UserRole.superuser;
      default:
        return UserRole.karyawan;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.karyawan:
        writer.writeByte(0);
      case UserRole.leader:
        writer.writeByte(1);
      case UserRole.supervisor:
        writer.writeByte(2);
      case UserRole.manager:
        writer.writeByte(3);
      case UserRole.superuser:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final typeId = 7;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.clockIn;
      case 1:
        return AttendanceStatus.clockOut;
      default:
        return AttendanceStatus.clockIn;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.clockIn:
        writer.writeByte(0);
      case AttendanceStatus.clockOut:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LeaveStatusAdapter extends TypeAdapter<LeaveStatus> {
  @override
  final typeId = 8;

  @override
  LeaveStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LeaveStatus.pending;
      case 1:
        return LeaveStatus.approvedL1;
      case 2:
        return LeaveStatus.approvedL2;
      case 3:
        return LeaveStatus.approvedFinal;
      case 4:
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, LeaveStatus obj) {
    switch (obj) {
      case LeaveStatus.pending:
        writer.writeByte(0);
      case LeaveStatus.approvedL1:
        writer.writeByte(1);
      case LeaveStatus.approvedL2:
        writer.writeByte(2);
      case LeaveStatus.approvedFinal:
        writer.writeByte(3);
      case LeaveStatus.rejected:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
