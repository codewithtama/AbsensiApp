import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/leave_model.dart';

class LeaveLocalDatasource {
  Box<LeaveModel> get _box => Hive.box<LeaveModel>(HiveBoxes.leaves);

  Future<void> saveLeave(LeaveModel leave) async {
    await _box.put(leave.id, leave);
  }

  LeaveModel? getLeaveById(String id) {
    return _box.get(id);
  }

  List<LeaveModel> getLeavesByUser(String userId) {
    return _box.values.where((l) => l.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveModel> getLeavesByStatus(LeaveStatus status) {
    return _box.values.where((l) => l.status == status).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveModel> getPendingLeavesForApproval(UserRole approverRole) {
    switch (approverRole) {
      case UserRole.leader:
        return _box.values
            .where((l) => l.status == LeaveStatus.pending)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case UserRole.supervisor:
        return _box.values
            .where((l) => l.status == LeaveStatus.approvedL1)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case UserRole.manager:
        return _box.values
            .where((l) => l.status == LeaveStatus.approvedL2)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        return [];
    }
  }

  Future<void> updateLeaveStatus(
    String leaveId,
    LeaveStatus status, {
    String? approvedBy,
    UserRole? approverRole,
  }) async {
    final leave = _box.get(leaveId);
    if (leave == null) return;

    leave.status = status;

    if (approvedBy != null && approverRole != null) {
      switch (approverRole) {
        case UserRole.leader:
          leave.approvedByLeader = approvedBy;
          break;
        case UserRole.supervisor:
          leave.approvedBySupervisor = approvedBy;
          break;
        case UserRole.manager:
          leave.approvedByManager = approvedBy;
          break;
        default:
          break;
      }
    }

    await leave.save();
  }

  List<LeaveModel> getAllLeaves() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
