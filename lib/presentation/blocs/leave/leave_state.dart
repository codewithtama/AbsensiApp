import 'package:equatable/equatable.dart';
import 'package:absensi_app/data/models/leave_model.dart';

sealed class LeaveState extends Equatable {
  const LeaveState();
  @override
  List<Object?> get props => [];
}

class LeaveInitial extends LeaveState {
  const LeaveInitial();
}

class LeaveLoading extends LeaveState {
  const LeaveLoading();
}

class LeaveSubmitted extends LeaveState {
  const LeaveSubmitted();
}

class LeaveApproved extends LeaveState {
  final String leaveId;
  const LeaveApproved({required this.leaveId});
  @override
  List<Object?> get props => [leaveId];
}

class LeaveRejected extends LeaveState {
  final String leaveId;
  const LeaveRejected({required this.leaveId});
  @override
  List<Object?> get props => [leaveId];
}

class LeavesLoaded extends LeaveState {
  final List<LeaveModel> leaves;
  const LeavesLoaded({required this.leaves});
  @override
  List<Object?> get props => [leaves.length];
}

class LeaveError extends LeaveState {
  final String message;
  const LeaveError({required this.message});
  @override
  List<Object?> get props => [message];
}
