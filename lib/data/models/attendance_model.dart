import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: HiveTypeIds.attendance)
class AttendanceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String siteId;

  @HiveField(3)
  final String? shiftId;

  @HiveField(4)
  final AttendanceStatus status;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final double latitude;

  @HiveField(7)
  final double longitude;

  @HiveField(8)
  final String? deviceName;

  @HiveField(9)
  final String? deviceOs;

  @HiveField(10)
  final String? networkType;

  @HiveField(11)
  final bool? isLate;

  @HiveField(12)
  final bool? isEarlyOut;

  @HiveField(13)
  final int? delayMinutes;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.siteId,
    this.shiftId,
    required this.status,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.deviceName,
    this.deviceOs,
    this.networkType,
    this.isLate,
    this.isEarlyOut,
    this.delayMinutes,
  });
}
