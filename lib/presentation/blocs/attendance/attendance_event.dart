import 'package:equatable/equatable.dart';

sealed class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class ClockInRequested extends AttendanceEvent {
  final String siteId;

  const ClockInRequested({required this.siteId});

  @override
  List<Object?> get props => [siteId];
}

class ClockOutRequested extends AttendanceEvent {
  final String siteId;

  const ClockOutRequested({required this.siteId});

  @override
  List<Object?> get props => [siteId];
}

class LoadAttendanceHistory extends AttendanceEvent {
  final String userId;

  const LoadAttendanceHistory({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadTeamAttendance extends AttendanceEvent {
  final DateTime? date;

  const LoadTeamAttendance({this.date});

  @override
  List<Object?> get props => [date];
}

class CheckTodayStatus extends AttendanceEvent {
  final String userId;

  const CheckTodayStatus({required this.userId});

  @override
  List<Object?> get props => [userId];
}
