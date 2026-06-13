import 'package:hive_ce/hive.dart';

part 'app_constants.g.dart';

/// Role-based access control constants
@HiveType(typeId: HiveTypeIds.userRole)
enum UserRole {
  @HiveField(0)
  karyawan,
  @HiveField(1)
  leader,
  @HiveField(2)
  supervisor,
  @HiveField(3)
  manager,
  @HiveField(4)
  superuser,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.karyawan:
        return 'Karyawan';
      case UserRole.leader:
        return 'Leader';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.manager:
        return 'Manager';
      case UserRole.superuser:
        return 'Superuser';
    }
  }

  int get approvalLevel {
    switch (this) {
      case UserRole.leader:
        return 1;
      case UserRole.supervisor:
        return 2;
      case UserRole.manager:
        return 3;
      default:
        return 0;
    }
  }

  bool get canApproveLeave =>
      this == UserRole.leader ||
      this == UserRole.supervisor ||
      this == UserRole.manager;

  bool get canManageShifts =>
      this == UserRole.supervisor || this == UserRole.superuser;

  bool get canManageSites => this == UserRole.superuser;

  bool get canManageUsers => this == UserRole.superuser;

  bool get canUnbindDevice => this == UserRole.superuser;

  bool get canViewTeamAttendance =>
      this == UserRole.leader ||
      this == UserRole.supervisor ||
      this == UserRole.manager ||
      this == UserRole.superuser;
}

/// Attendance status
@HiveType(typeId: HiveTypeIds.attendanceStatus)
enum AttendanceStatus {
  @HiveField(0)
  clockIn,
  @HiveField(1)
  clockOut,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.clockIn:
        return 'Clock In';
      case AttendanceStatus.clockOut:
        return 'Clock Out';
    }
  }
}

/// Leave approval status — multi-level pipeline
@HiveType(typeId: HiveTypeIds.leaveStatus)
enum LeaveStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approvedL1,
  @HiveField(2)
  approvedL2,
  @HiveField(3)
  approvedFinal,
  @HiveField(4)
  rejected,
}

extension LeaveStatusExtension on LeaveStatus {
  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Menunggu Persetujuan';
      case LeaveStatus.approvedL1:
        return 'Disetujui Leader';
      case LeaveStatus.approvedL2:
        return 'Disetujui Supervisor';
      case LeaveStatus.approvedFinal:
        return 'Disetujui Final';
      case LeaveStatus.rejected:
        return 'Ditolak';
    }
  }

  bool get isTerminal =>
      this == LeaveStatus.approvedFinal || this == LeaveStatus.rejected;
}

/// Hive box names
abstract final class HiveBoxes {
  static const String users = 'users';
  static const String sites = 'sites';
  static const String shifts = 'shifts';
  static const String attendance = 'attendance';
  static const String leaves = 'leaves';
  static const String shiftAssignments = 'shift_assignments';
  static const String appSettings = 'app_settings';
}

/// Hive type IDs
abstract final class HiveTypeIds {
  static const int user = 0;
  static const int site = 1;
  static const int shift = 2;
  static const int attendance = 3;
  static const int leave = 4;
  static const int shiftAssignment = 5;
  static const int userRole = 6;
  static const int attendanceStatus = 7;
  static const int leaveStatus = 8;
}

/// Default geofence config
abstract final class GeofenceConfig {
  static const double defaultRadiusMeters = 100.0;
  static const double earthRadiusKm = 6371.0;
}

/// App-level settings keys
abstract final class AppSettingsKeys {
  static const String isSeeded = 'is_seeded';
  static const String currentUserId = 'current_user_id';
}
