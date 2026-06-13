import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'leave_model.g.dart';

@HiveType(typeId: HiveTypeIds.leave)
class LeaveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime endDate;

  @HiveField(4)
  final String reason;

  @HiveField(5)
  LeaveStatus status;

  @HiveField(6)
  String? approvedByLeader;

  @HiveField(7)
  String? approvedBySupervisor;

  @HiveField(8)
  String? approvedByManager;

  @HiveField(9)
  String? documentPath;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final String type; // 'Cuti', 'Sakit', 'Izin'

  LeaveModel({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.approvedByLeader,
    this.approvedBySupervisor,
    this.approvedByManager,
    this.documentPath,
    required this.createdAt,
    this.type = 'Cuti',
  });
}
