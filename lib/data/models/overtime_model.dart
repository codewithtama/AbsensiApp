import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'overtime_model.g.dart';

@HiveType(typeId: HiveTypeIds.overtime)
class OvertimeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String siteId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String startTime; // "HH:mm" format

  @HiveField(5)
  final String endTime; // "HH:mm" format

  @HiveField(6)
  final String reason;

  @HiveField(7)
  final OvertimeStatus status;

  @HiveField(8)
  final String? approvedBy;

  @HiveField(9)
  final String? instructedBy; // Who ordered/commanded this overtime (if any)

  OvertimeModel({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.instructedBy,
  });

  OvertimeModel copyWith({
    String? id,
    String? userId,
    String? siteId,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? reason,
    OvertimeStatus? status,
    String? approvedBy,
    String? instructedBy,
  }) {
    return OvertimeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      siteId: siteId ?? this.siteId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      instructedBy: instructedBy ?? this.instructedBy,
    );
  }
}
