import 'package:equatable/equatable.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

sealed class LeaveEvent extends Equatable {
  const LeaveEvent();
  @override
  List<Object?> get props => [];
}

class SubmitLeave extends LeaveEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? documentPath;

  const SubmitLeave({
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentPath,
  });

  @override
  List<Object?> get props => [startDate, endDate, reason, documentPath];
}

class ApproveLeave extends LeaveEvent {
  final String leaveId;
  final UserRole approverRole;
  final String approverId;

  const ApproveLeave({
    required this.leaveId,
    required this.approverRole,
    required this.approverId,
  });

  @override
  List<Object?> get props => [leaveId, approverRole, approverId];
}

class RejectLeave extends LeaveEvent {
  final String leaveId;
  final String rejectedBy;

  const RejectLeave({required this.leaveId, required this.rejectedBy});

  @override
  List<Object?> get props => [leaveId, rejectedBy];
}

class LoadMyLeaves extends LeaveEvent {
  final String userId;
  const LoadMyLeaves({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadPendingApprovals extends LeaveEvent {
  final UserRole approverRole;
  const LoadPendingApprovals({required this.approverRole});
  @override
  List<Object?> get props => [approverRole];
}

class LoadAllLeaves extends LeaveEvent {
  const LoadAllLeaves();
}
