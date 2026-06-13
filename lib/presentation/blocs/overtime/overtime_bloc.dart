import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/datasources/overtime_local_datasource.dart';
import 'package:absensi_app/data/models/overtime_model.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_event.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_state.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final OvertimeLocalDatasource _overtimeDatasource;
  final String _currentUserId;

  OvertimeBloc({
    required OvertimeLocalDatasource overtimeDatasource,
    required String currentUserId,
  })  : _overtimeDatasource = overtimeDatasource,
        _currentUserId = currentUserId,
        super(const OvertimeInitial()) {
    on<SubmitOvertimeRequest>(_onSubmit);
    on<CreateOvertimeMandate>(_onMandate);
    on<ApproveOvertime>(_onApprove);
    on<RejectOvertime>(_onReject);
    on<LoadMyOvertimes>(_onLoadMyOvertimes);
    on<LoadPendingOvertimeApprovals>(_onLoadPending);
    on<LoadAllOvertimes>(_onLoadAll);
  }

  Future<void> _onSubmit(SubmitOvertimeRequest event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtime = OvertimeModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        siteId: event.siteId,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        reason: event.reason,
        status: OvertimeStatus.pending,
        instructedBy: event.instructedBy,
      );
      await _overtimeDatasource.saveOvertime(overtime);
      emit(const OvertimeSubmitted());
    } catch (e) {
      emit(OvertimeError(message: 'Gagal mengajukan lembur: ${e.toString()}'));
    }
  }

  Future<void> _onMandate(CreateOvertimeMandate event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtime = OvertimeModel(
        id: const Uuid().v4(),
        userId: event.userId,
        siteId: event.siteId,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        reason: event.reason,
        status: OvertimeStatus.approvedFinal, // Direct command is automatically final approved
        instructedBy: event.instructedBy,
        approvedBy: event.instructedBy,
      );
      await _overtimeDatasource.saveOvertime(overtime);
      emit(const OvertimeSuccess(message: 'Perintah lembur berhasil dikirim ke karyawan.'));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal memberikan perintah lembur: ${e.toString()}'));
    }
  }

  Future<void> _onApprove(ApproveOvertime event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtime = _overtimeDatasource.getOvertimeById(event.overtimeId);
      if (overtime == null) {
        emit(const OvertimeError(message: 'Data lembur tidak ditemukan.'));
        return;
      }

      OvertimeStatus nextStatus;
      switch (event.approverRole) {
        case UserRole.leader:
          if (overtime.status != OvertimeStatus.pending) {
            emit(const OvertimeError(message: 'Lembur ini tidak dalam status menunggu persetujuan.'));
            return;
          }
          nextStatus = OvertimeStatus.approvedL1;
          break;
        case UserRole.supervisor:
          if (overtime.status != OvertimeStatus.pending && overtime.status != OvertimeStatus.approvedL1) {
            emit(const OvertimeError(message: 'Lembur tidak berada pada status yang dapat disetujui Supervisor.'));
            return;
          }
          nextStatus = OvertimeStatus.approvedL2;
          break;
        case UserRole.manager:
        case UserRole.superuser:
          if (overtime.status != OvertimeStatus.pending &&
              overtime.status != OvertimeStatus.approvedL1 &&
              overtime.status != OvertimeStatus.approvedL2) {
            emit(const OvertimeError(message: 'Lembur tidak berada pada status yang dapat disetujui Manajer/Superuser.'));
            return;
          }
          nextStatus = OvertimeStatus.approvedFinal;
          break;
        default:
          emit(const OvertimeError(message: 'Tidak memiliki akses persetujuan lembur.'));
          return;
      }

      await _overtimeDatasource.updateOvertimeStatus(
        event.overtimeId,
        nextStatus,
        approvedBy: event.approverId,
      );

      emit(OvertimeApproved(overtimeId: event.overtimeId));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal menyetujui lembur: ${e.toString()}'));
    }
  }

  Future<void> _onReject(RejectOvertime event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      await _overtimeDatasource.updateOvertimeStatus(
        event.overtimeId,
        OvertimeStatus.rejected,
        approvedBy: event.rejectedBy,
      );
      emit(OvertimeRejected(overtimeId: event.overtimeId));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal menolak lembur: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMyOvertimes(LoadMyOvertimes event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtimes = _overtimeDatasource.getOvertimesByUser(event.userId);
      emit(OvertimesLoaded(overtimes: overtimes));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal memuat daftar lembur Anda: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPending(LoadPendingOvertimeApprovals event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtimes = _overtimeDatasource.getPendingOvertimesForApproval(event.approverRole);
      emit(OvertimesLoaded(overtimes: overtimes));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal memuat daftar persetujuan lembur: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAll(LoadAllOvertimes event, Emitter<OvertimeState> emit) async {
    emit(const OvertimeLoading());
    try {
      final overtimes = _overtimeDatasource.getAllOvertimes();
      emit(OvertimesLoaded(overtimes: overtimes));
    } catch (e) {
      emit(OvertimeError(message: 'Gagal memuat semua data lembur: ${e.toString()}'));
    }
  }
}
