import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'shift_assignment_model.g.dart';

@HiveType(typeId: HiveTypeIds.shiftAssignment)
class ShiftAssignmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String shiftId;

  @HiveField(3)
  final String siteId;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String assignedBy;

  ShiftAssignmentModel({
    required this.id,
    required this.userId,
    required this.shiftId,
    required this.siteId,
    required this.date,
    required this.assignedBy,
  });
}
