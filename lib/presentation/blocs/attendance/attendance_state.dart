import 'package:equatable/equatable.dart';
import 'package:absensi_app/data/models/attendance_model.dart';

sealed class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  final String? stepMessage;
  const AttendanceLoading({this.stepMessage});

  @override
  List<Object?> get props => [stepMessage];
}

class AttendanceStatusChecked extends AttendanceState {
  final bool isClockedIn;
  final AttendanceModel? todayClockIn;

  const AttendanceStatusChecked({
    required this.isClockedIn,
    this.todayClockIn,
  });

  @override
  List<Object?> get props => [isClockedIn, todayClockIn?.id];
}

class ClockInSuccess extends AttendanceState {
  final AttendanceModel attendance;

  const ClockInSuccess({required this.attendance});

  @override
  List<Object?> get props => [attendance.id];
}

class ClockOutSuccess extends AttendanceState {
  final AttendanceModel attendance;
  final Duration? workDuration;

  const ClockOutSuccess({required this.attendance, this.workDuration});

  @override
  List<Object?> get props => [attendance.id, workDuration];
}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<AttendanceModel> records;

  const AttendanceHistoryLoaded({required this.records});

  @override
  List<Object?> get props => [records.length];
}

class AttendanceError extends AttendanceState {
  final String message;
  final String? errorType;

  const AttendanceError({required this.message, this.errorType});

  @override
  List<Object?> get props => [message, errorType];
}
