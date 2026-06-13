import 'package:equatable/equatable.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

sealed class OvertimeEvent extends Equatable {
  const OvertimeEvent();
  @override
  List<Object?> get props => [];
}

class SubmitOvertimeRequest extends OvertimeEvent {
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reason;
  final String siteId;
  final String? instructedBy;

  const SubmitOvertimeRequest({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.siteId,
    this.instructedBy,
  });

  @override
  List<Object?> get props => [date, startTime, endTime, reason, siteId, instructedBy];
}

class CreateOvertimeMandate extends OvertimeEvent {
  final String userId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reason;
  final String siteId;
  final String instructedBy;

  const CreateOvertimeMandate({
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.siteId,
    required this.instructedBy,
  });

  @override
  List<Object?> get props => [userId, date, startTime, endTime, reason, siteId, instructedBy];
}

class ApproveOvertime extends OvertimeEvent {
  final String overtimeId;
  final UserRole approverRole;
  final String approverId;

  const ApproveOvertime({
    required this.overtimeId,
    required this.approverRole,
    required this.approverId,
  });

  @override
  List<Object?> get props => [overtimeId, approverRole, approverId];
}

class RejectOvertime extends OvertimeEvent {
  final String overtimeId;
  final String rejectedBy;

  const RejectOvertime({required this.overtimeId, required this.rejectedBy});

  @override
  List<Object?> get props => [overtimeId, rejectedBy];
}

class LoadMyOvertimes extends OvertimeEvent {
  final String userId;
  const LoadMyOvertimes({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadPendingOvertimeApprovals extends OvertimeEvent {
  final UserRole approverRole;
  const LoadPendingOvertimeApprovals({required this.approverRole});
  @override
  List<Object?> get props => [approverRole];
}

class LoadAllOvertimes extends OvertimeEvent {
  const LoadAllOvertimes();
}
