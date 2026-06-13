import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/datasources/leave_local_datasource.dart';
import 'package:absensi_app/data/models/leave_model.dart';
import 'package:absensi_app/presentation/blocs/leave/leave_event.dart';
import 'package:absensi_app/presentation/blocs/leave/leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveLocalDatasource _leaveDatasource;
  final String _currentUserId;

  LeaveBloc({
    required LeaveLocalDatasource leaveDatasource,
    required String currentUserId,
  })  : _leaveDatasource = leaveDatasource,
        _currentUserId = currentUserId,
        super(const LeaveInitial()) {
    on<SubmitLeave>(_onSubmit);
    on<ApproveLeave>(_onApprove);
    on<RejectLeave>(_onReject);
    on<LoadMyLeaves>(_onLoadMyLeaves);
    on<LoadPendingApprovals>(_onLoadPending);
    on<LoadAllLeaves>(_onLoadAll);
  }

  Future<void> _onSubmit(SubmitLeave event, Emitter<LeaveState> emit) async {
    emit(const LeaveLoading());
    try {
      final leave = LeaveModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
        status: LeaveStatus.pending,
        documentPath: event.documentPath,
        createdAt: DateTime.now(),
        type: event.type,
      );
      await _leaveDatasource.saveLeave(leave);
      emit(const LeaveSubmitted());
    } catch (e) {
      emit(LeaveError(message: 'Gagal mengajukan permohonan: ${e.toString()}'));
    }
  }

  Future<void> _onApprove(ApproveLeave event, Emitter<LeaveState> emit) async {
    emit(const LeaveLoading());
    try {
      final leave = _leaveDatasource.getLeaveById(event.leaveId);
      if (leave == null) {
        emit(const LeaveError(message: 'Data cuti tidak ditemukan.'));
        return;
      }

      LeaveStatus nextStatus;
      switch (event.approverRole) {
        case UserRole.leader:
          if (leave.status != LeaveStatus.pending) {
            emit(const LeaveError(message: 'Permohonan ini tidak dalam status menunggu persetujuan.'));
            return;
          }
          nextStatus = LeaveStatus.approvedL1;
          break;
        case UserRole.supervisor:
          if (leave.status != LeaveStatus.pending && leave.status != LeaveStatus.approvedL1) {
            emit(const LeaveError(message: 'Permohonan tidak berada pada status yang dapat disetujui Supervisor.'));
            return;
          }
          nextStatus = LeaveStatus.approvedL2;
          break;
        case UserRole.manager:
          if (leave.status != LeaveStatus.pending &&
              leave.status != LeaveStatus.approvedL1 &&
              leave.status != LeaveStatus.approvedL2) {
            emit(const LeaveError(message: 'Permohonan tidak berada pada status yang dapat disetujui Manajer.'));
            return;
          }
          nextStatus = LeaveStatus.approvedFinal;
          break;
        default:
          emit(const LeaveError(message: 'Tidak memiliki akses approval.'));
          return;
      }

      await _leaveDatasource.updateLeaveStatus(
        event.leaveId,
        nextStatus,
        approvedBy: event.approverId,
        approverRole: event.approverRole,
      );

      emit(LeaveApproved(leaveId: event.leaveId));
    } catch (e) {
      emit(LeaveError(message: 'Gagal approve cuti: ${e.toString()}'));
    }
  }

  Future<void> _onReject(RejectLeave event, Emitter<LeaveState> emit) async {
    emit(const LeaveLoading());
    try {
      await _leaveDatasource.updateLeaveStatus(
        event.leaveId,
        LeaveStatus.rejected,
      );
      emit(LeaveRejected(leaveId: event.leaveId));
    } catch (e) {
      emit(LeaveError(message: 'Gagal menolak cuti: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMyLeaves(
    LoadMyLeaves event,
    Emitter<LeaveState> emit,
  ) async {
    emit(const LeaveLoading());
    try {
      final leaves = _leaveDatasource.getLeavesByUser(event.userId);
      emit(LeavesLoaded(leaves: leaves));
    } catch (e) {
      emit(LeaveError(message: 'Gagal memuat daftar permohonan cuti Anda: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPending(
    LoadPendingApprovals event,
    Emitter<LeaveState> emit,
  ) async {
    emit(const LeaveLoading());
    try {
      final leaves =
          _leaveDatasource.getPendingLeavesForApproval(event.approverRole);
      emit(LeavesLoaded(leaves: leaves));
    } catch (e) {
      emit(LeaveError(message: 'Gagal memuat daftar menunggu persetujuan: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAll(
    LoadAllLeaves event,
    Emitter<LeaveState> emit,
  ) async {
    emit(const LeaveLoading());
    try {
      final leaves = _leaveDatasource.getAllLeaves();
      emit(LeavesLoaded(leaves: leaves));
    } catch (e) {
      emit(LeaveError(message: 'Gagal memuat semua data permohonan cuti: ${e.toString()}'));
    }
  }
}
