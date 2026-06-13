import 'package:equatable/equatable.dart';
import 'package:absensi_app/data/models/overtime_model.dart';

sealed class OvertimeState extends Equatable {
  const OvertimeState();
  @override
  List<Object?> get props => [];
}

class OvertimeInitial extends OvertimeState {
  const OvertimeInitial();
}

class OvertimeLoading extends OvertimeState {
  const OvertimeLoading();
}

class OvertimeSubmitted extends OvertimeState {
  const OvertimeSubmitted();
}

class OvertimeApproved extends OvertimeState {
  final String overtimeId;
  const OvertimeApproved({required this.overtimeId});
  @override
  List<Object?> get props => [overtimeId];
}

class OvertimeRejected extends OvertimeState {
  final String overtimeId;
  const OvertimeRejected({required this.overtimeId});
  @override
  List<Object?> get props => [overtimeId];
}

class OvertimesLoaded extends OvertimeState {
  final List<OvertimeModel> overtimes;
  const OvertimesLoaded({required this.overtimes});
  @override
  List<Object?> get props => [overtimes.length];
}

class OvertimeSuccess extends OvertimeState {
  final String message;
  const OvertimeSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class OvertimeError extends OvertimeState {
  final String message;
  const OvertimeError({required this.message});
  @override
  List<Object?> get props => [message];
}
