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

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.siteId,
    this.shiftId,
    required this.status,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });
}
