import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/site_model.dart';
import 'package:absensi_app/data/models/shift_model.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';

// ── Events ──
sealed class ManagementEvent extends Equatable {
  const ManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends ManagementEvent {
  const LoadUsers();
}

class CreateUser extends ManagementEvent {
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const CreateUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, role];
}

class DeleteUser extends ManagementEvent {
  final String userId;
  const DeleteUser({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class UnbindDevice extends ManagementEvent {
  final String userId;
  const UnbindDevice({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadSites extends ManagementEvent {
  const LoadSites();
}

class CreateSite extends ManagementEvent {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const CreateSite({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  @override
  List<Object?> get props => [name, latitude, longitude, radiusMeters];
}

class DeleteSite extends ManagementEvent {
  final String siteId;
  const DeleteSite({required this.siteId});
  @override
  List<Object?> get props => [siteId];
}

class LoadShifts extends ManagementEvent {
  const LoadShifts();
}

class CreateShift extends ManagementEvent {
  final String name;
  final String startTime;
  final String endTime;

  const CreateShift({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [name, startTime, endTime];
}

class DeleteShift extends ManagementEvent {
  final String shiftId;
  const DeleteShift({required this.shiftId});
  @override
  List<Object?> get props => [shiftId];
}

class AssignShift extends ManagementEvent {
  final String userId;
  final String shiftId;
  final String siteId;
  final DateTime date;
  final String assignedBy;

  const AssignShift({
    required this.userId,
    required this.shiftId,
    required this.siteId,
    required this.date,
    required this.assignedBy,
  });

  @override
  List<Object?> get props => [userId, shiftId, siteId, date];
}

class AssignShiftRange extends ManagementEvent {
  final List<String> userIds;
  final String shiftId;
  final String siteId;
  final DateTime startDate;
  final DateTime endDate;
  final String assignedBy;

  const AssignShiftRange({
    required this.userIds,
    required this.shiftId,
    required this.siteId,
    required this.startDate,
    required this.endDate,
    required this.assignedBy,
  });

  @override
  List<Object?> get props => [
    userIds,
    shiftId,
    siteId,
    startDate,
    endDate,
    assignedBy,
  ];
}

class CopyAssignmentsRange extends ManagementEvent {
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final String assignedBy;

  const CopyAssignmentsRange({
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    required this.assignedBy,
  });

  @override
  List<Object?> get props => [
        sourceStartDate,
        sourceEndDate,
        targetStartDate,
        assignedBy,
      ];
}

class DeleteAssignmentsRange extends ManagementEvent {
  final List<String> userIds;
  final DateTime startDate;
  final DateTime endDate;

  const DeleteAssignmentsRange({
    required this.userIds,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userIds, startDate, endDate];
}

class SwapAssignments extends ManagementEvent {
  final String firstUserId;
  final String secondUserId;
  final DateTime date;
  final String assignedBy;

  const SwapAssignments({
    required this.firstUserId,
    required this.secondUserId,
    required this.date,
    required this.assignedBy,
  });

  @override
  List<Object?> get props => [firstUserId, secondUserId, date, assignedBy];
}

class LoadShiftAssignments extends ManagementEvent {
  final DateTime? date;
  final String? siteId;

  const LoadShiftAssignments({this.date, this.siteId});

  @override
  List<Object?> get props => [date, siteId];
}

class UpdateUser extends ManagementEvent {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? password;

  const UpdateUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.password,
  });

  @override
  List<Object?> get props => [userId, name, email, role, password];
}

class UpdateSite extends ManagementEvent {
  final String siteId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const UpdateSite({
    required this.siteId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  @override
  List<Object?> get props => [siteId, name, latitude, longitude, radiusMeters];
}

class UpdateShift extends ManagementEvent {
  final String shiftId;
  final String name;
  final String startTime;
  final String endTime;

  const UpdateShift({
    required this.shiftId,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [shiftId, name, startTime, endTime];
}

class DeleteAssignment extends ManagementEvent {
  final String assignmentId;
  const DeleteAssignment({required this.assignmentId});
  @override
  List<Object?> get props => [assignmentId];
}

class UpdateAssignment extends ManagementEvent {
  final String assignmentId;
  final String userId;
  final String shiftId;
  final String siteId;
  final DateTime date;
  final String assignedBy;

  const UpdateAssignment({
    required this.assignmentId,
    required this.userId,
    required this.shiftId,
    required this.siteId,
    required this.date,
    required this.assignedBy,
  });

  @override
  List<Object?> get props => [assignmentId, userId, shiftId, siteId, date];
}

// ── States ──
sealed class ManagementState extends Equatable {
  const ManagementState();
  @override
  List<Object?> get props => [];
}

class ManagementInitial extends ManagementState {
  const ManagementInitial();
}

class ManagementLoading extends ManagementState {
  const ManagementLoading();
}

class UsersLoaded extends ManagementState {
  final List<UserModel> users;
  const UsersLoaded({required this.users});
  @override
  List<Object?> get props => [users.length];
}

class SitesLoaded extends ManagementState {
  final List<SiteModel> sites;
  const SitesLoaded({required this.sites});
  @override
  List<Object?> get props => [sites.length];
}

class ShiftsLoaded extends ManagementState {
  final List<ShiftModel> shifts;
  const ShiftsLoaded({required this.shifts});
  @override
  List<Object?> get props => [shifts.length];
}

class ShiftAssignmentsLoaded extends ManagementState {
  final List<ShiftAssignmentModel> assignments;
  const ShiftAssignmentsLoaded({required this.assignments});
  @override
  List<Object?> get props => [assignments.length];
}

class ManagementSuccess extends ManagementState {
  final String message;
  const ManagementSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class ManagementError extends ManagementState {
  final String message;
  const ManagementError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class ManagementBloc extends Bloc<ManagementEvent, ManagementState> {
  final UserLocalDatasource _userDatasource;
  final SiteLocalDatasource _siteDatasource;
  final ShiftLocalDatasource _shiftDatasource;
  final ShiftAssignmentLocalDatasource _assignmentDatasource;

  ManagementBloc({
    required UserLocalDatasource userDatasource,
    required SiteLocalDatasource siteDatasource,
    required ShiftLocalDatasource shiftDatasource,
    required ShiftAssignmentLocalDatasource assignmentDatasource,
  }) : _userDatasource = userDatasource,
       _siteDatasource = siteDatasource,
       _shiftDatasource = shiftDatasource,
       _assignmentDatasource = assignmentDatasource,
       super(const ManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<DeleteUser>(_onDeleteUser);
    on<UnbindDevice>(_onUnbindDevice);
    on<LoadSites>(_onLoadSites);
    on<CreateSite>(_onCreateSite);
    on<DeleteSite>(_onDeleteSite);
    on<LoadShifts>(_onLoadShifts);
    on<CreateShift>(_onCreateShift);
    on<DeleteShift>(_onDeleteShift);
    on<AssignShift>(_onAssignShift);
    on<AssignShiftRange>(_onAssignShiftRange);
    on<CopyAssignmentsRange>(_onCopyAssignmentsRange);
    on<DeleteAssignmentsRange>(_onDeleteAssignmentsRange);
    on<SwapAssignments>(_onSwapAssignments);
    on<LoadShiftAssignments>(_onLoadAssignments);
    on<DeleteAssignment>(_onDeleteAssignment);
    on<UpdateAssignment>(_onUpdateAssignment);
    on<UpdateUser>(_onUpdateUser);
    on<UpdateSite>(_onUpdateSite);
    on<UpdateShift>(_onUpdateShift);
  }

  void _onLoadUsers(LoadUsers event, Emitter<ManagementState> emit) {
    emit(const ManagementLoading());
    try {
      final users = _userDatasource.getAllUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(
        ManagementError(
          message: 'Gagal memuat daftar pengguna: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      if (_userDatasource.getUserByEmail(event.email) != null) {
        emit(const ManagementError(message: 'Email sudah terdaftar.'));
        return;
      }

      final hashedPassword = BCrypt.hashpw(event.password, BCrypt.gensalt());
      final user = UserModel(
        id: const Uuid().v4(),
        name: event.name,
        email: event.email,
        passwordHash: hashedPassword,
        role: event.role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userDatasource.saveUser(user);
      emit(const ManagementSuccess(message: 'Pengguna berhasil dibuat.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal membuat pengguna: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<ManagementState> emit,
  ) async {
    await _userDatasource.deleteUser(event.userId);
    emit(const ManagementSuccess(message: 'Pengguna dihapus.'));
  }

  Future<void> _onUnbindDevice(
    UnbindDevice event,
    Emitter<ManagementState> emit,
  ) async {
    await _userDatasource.updateDeviceId(event.userId, null);
    emit(
      const ManagementSuccess(message: 'Tautan perangkat berhasil dilepas.'),
    );
  }

  void _onLoadSites(LoadSites event, Emitter<ManagementState> emit) {
    emit(const ManagementLoading());
    try {
      final sites = _siteDatasource.getAllSites();
      emit(SitesLoaded(sites: sites));
    } catch (e) {
      emit(
        ManagementError(
          message: 'Gagal memuat daftar lokasi kerja: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreateSite(
    CreateSite event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final site = SiteModel(
        id: const Uuid().v4(),
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
      );
      await _siteDatasource.saveSite(site);
      emit(const ManagementSuccess(message: 'Site berhasil dibuat.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal membuat site: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteSite(
    DeleteSite event,
    Emitter<ManagementState> emit,
  ) async {
    await _siteDatasource.deleteSite(event.siteId);
    emit(const ManagementSuccess(message: 'Site dihapus.'));
  }

  void _onLoadShifts(LoadShifts event, Emitter<ManagementState> emit) {
    emit(const ManagementLoading());
    try {
      final shifts = _shiftDatasource.getAllShifts();
      emit(ShiftsLoaded(shifts: shifts));
    } catch (e) {
      emit(
        ManagementError(message: 'Gagal memuat daftar shift: ${e.toString()}'),
      );
    }
  }

  Future<void> _onCreateShift(
    CreateShift event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final shift = ShiftModel(
        id: const Uuid().v4(),
        name: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
      );
      await _shiftDatasource.saveShift(shift);
      emit(const ManagementSuccess(message: 'Shift berhasil dibuat.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal membuat shift: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteShift(
    DeleteShift event,
    Emitter<ManagementState> emit,
  ) async {
    await _shiftDatasource.deleteShift(event.shiftId);
    emit(const ManagementSuccess(message: 'Shift dihapus.'));
  }

  Future<void> _onAssignShift(
    AssignShift event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final existing = _assignmentDatasource.getAssignmentForUserOnDate(
        event.userId,
        event.date,
      );
      final assignment = ShiftAssignmentModel(
        id: existing?.id ?? const Uuid().v4(),
        userId: event.userId,
        shiftId: event.shiftId,
        siteId: event.siteId,
        date: event.date,
        assignedBy: event.assignedBy,
      );
      await _assignmentDatasource.saveAssignment(assignment);
      emit(const ManagementSuccess(message: 'Shift berhasil di-assign.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal assign shift: ${e.toString()}'));
    }
  }

  Future<void> _onAssignShiftRange(
    AssignShiftRange event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      if (event.userIds.isEmpty) {
        emit(const ManagementError(message: 'Pilih minimal satu pengguna.'));
        return;
      }

      final start = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final end = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );

      if (end.isBefore(start)) {
        emit(
          const ManagementError(
            message: 'Tanggal selesai tidak boleh sebelum tanggal mulai.',
          ),
        );
        return;
      }

      var totalSaved = 0;
      for (final userId in event.userIds) {
        var current = start;
        while (!current.isAfter(end)) {
          final existing = _assignmentDatasource.getAssignmentForUserOnDate(
            userId,
            current,
          );
          final assignment = ShiftAssignmentModel(
            id: existing?.id ?? const Uuid().v4(),
            userId: userId,
            shiftId: event.shiftId,
            siteId: event.siteId,
            date: current,
            assignedBy: event.assignedBy,
          );
          await _assignmentDatasource.saveAssignment(assignment);
          totalSaved++;
          current = current.add(const Duration(days: 1));
        }
      }

      emit(
        ManagementSuccess(
          message: '$totalSaved jadwal berhasil dibuat/diperbarui.',
        ),
      );
    } catch (e) {
      emit(
        ManagementError(
          message: 'Gagal membuat jadwal massal: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCopyAssignmentsRange(
    CopyAssignmentsRange event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final sourceStart = DateTime(
        event.sourceStartDate.year,
        event.sourceStartDate.month,
        event.sourceStartDate.day,
      );
      final sourceEnd = DateTime(
        event.sourceEndDate.year,
        event.sourceEndDate.month,
        event.sourceEndDate.day,
      );
      final targetStart = DateTime(
        event.targetStartDate.year,
        event.targetStartDate.month,
        event.targetStartDate.day,
      );

      if (sourceEnd.isBefore(sourceStart)) {
        emit(const ManagementError(
          message: 'Tanggal sumber selesai tidak boleh sebelum tanggal mulai.',
        ));
        return;
      }

      final sourceAssignments = _assignmentDatasource
          .getAllAssignments()
          .where((assignment) {
        final date = DateTime(
          assignment.date.year,
          assignment.date.month,
          assignment.date.day,
        );
        return !date.isBefore(sourceStart) && !date.isAfter(sourceEnd);
      }).toList();

      if (sourceAssignments.isEmpty) {
        emit(const ManagementError(
          message: 'Tidak ada jadwal pada rentang sumber.',
        ));
        return;
      }

      var totalSaved = 0;
      for (final source in sourceAssignments) {
        final sourceDate = DateTime(
          source.date.year,
          source.date.month,
          source.date.day,
        );
        final offsetDays = sourceDate.difference(sourceStart).inDays;
        final targetDate = targetStart.add(Duration(days: offsetDays));
        final existing = _assignmentDatasource.getAssignmentForUserOnDate(
          source.userId,
          targetDate,
        );

        await _assignmentDatasource.saveAssignment(
          ShiftAssignmentModel(
            id: existing?.id ?? const Uuid().v4(),
            userId: source.userId,
            shiftId: source.shiftId,
            siteId: source.siteId,
            date: targetDate,
            assignedBy: event.assignedBy,
          ),
        );
        totalSaved++;
      }

      emit(ManagementSuccess(
        message: '$totalSaved jadwal berhasil disalin.',
      ));
    } catch (e) {
      emit(ManagementError(
        message: 'Gagal menyalin jadwal: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteAssignmentsRange(
    DeleteAssignmentsRange event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      if (event.userIds.isEmpty) {
        emit(const ManagementError(message: 'Pilih minimal satu pengguna.'));
        return;
      }

      final start = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final end = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );

      if (end.isBefore(start)) {
        emit(const ManagementError(
          message: 'Tanggal selesai tidak boleh sebelum tanggal mulai.',
        ));
        return;
      }

      final toDelete = _assignmentDatasource.getAllAssignments().where((a) {
        final date = DateTime(a.date.year, a.date.month, a.date.day);
        return event.userIds.contains(a.userId) &&
            !date.isBefore(start) &&
            !date.isAfter(end);
      }).toList();

      for (final assignment in toDelete) {
        await _assignmentDatasource.deleteAssignment(assignment.id);
      }

      emit(ManagementSuccess(
        message: '${toDelete.length} jadwal berhasil dihapus.',
      ));
    } catch (e) {
      emit(ManagementError(
        message: 'Gagal menghapus jadwal massal: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSwapAssignments(
    SwapAssignments event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      if (event.firstUserId == event.secondUserId) {
        emit(const ManagementError(
          message: 'Pilih dua pengguna yang berbeda.',
        ));
        return;
      }

      final first = _assignmentDatasource.getAssignmentForUserOnDate(
        event.firstUserId,
        event.date,
      );
      final second = _assignmentDatasource.getAssignmentForUserOnDate(
        event.secondUserId,
        event.date,
      );

      if (first == null || second == null) {
        emit(const ManagementError(
          message: 'Kedua pengguna harus punya jadwal pada tanggal yang sama.',
        ));
        return;
      }

      await _assignmentDatasource.saveAssignment(
        ShiftAssignmentModel(
          id: first.id,
          userId: first.userId,
          shiftId: second.shiftId,
          siteId: second.siteId,
          date: first.date,
          assignedBy: event.assignedBy,
        ),
      );
      await _assignmentDatasource.saveAssignment(
        ShiftAssignmentModel(
          id: second.id,
          userId: second.userId,
          shiftId: first.shiftId,
          siteId: first.siteId,
          date: second.date,
          assignedBy: event.assignedBy,
        ),
      );

      emit(const ManagementSuccess(message: 'Shift berhasil ditukar.'));
    } catch (e) {
      emit(ManagementError(
        message: 'Gagal menukar shift: ${e.toString()}',
      ));
    }
  }

  void _onLoadAssignments(
    LoadShiftAssignments event,
    Emitter<ManagementState> emit,
  ) {
    emit(const ManagementLoading());
    try {
      List<ShiftAssignmentModel> assignments;
      if (event.date != null) {
        assignments = _assignmentDatasource.getAssignmentsByDate(event.date!);
      } else if (event.siteId != null) {
        assignments = _assignmentDatasource.getAssignmentsBySite(event.siteId!);
      } else {
        assignments = _assignmentDatasource.getAllAssignments();
      }
      emit(ShiftAssignmentsLoaded(assignments: assignments));
    } catch (e) {
      emit(
        ManagementError(
          message: 'Gagal memuat daftar penugasan: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteAssignment(
    DeleteAssignment event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      await _assignmentDatasource.deleteAssignment(event.assignmentId);
      emit(
        const ManagementSuccess(message: 'Penugasan jadwal berhasil dihapus.'),
      );
    } catch (e) {
      emit(
        ManagementError(message: 'Gagal menghapus penugasan: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateAssignment(
    UpdateAssignment event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final updated = ShiftAssignmentModel(
        id: event.assignmentId,
        userId: event.userId,
        shiftId: event.shiftId,
        siteId: event.siteId,
        date: event.date,
        assignedBy: event.assignedBy,
      );
      await _assignmentDatasource.saveAssignment(updated);
      emit(
        const ManagementSuccess(
          message: 'Penugasan jadwal berhasil diperbarui.',
        ),
      );
    } catch (e) {
      emit(
        ManagementError(
          message: 'Gagal memperbarui penugasan: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final user = _userDatasource.getUserById(event.userId);
      if (user == null) {
        emit(const ManagementError(message: 'Pengguna tidak ditemukan.'));
        return;
      }

      if (user.email != event.email &&
          _userDatasource.getUserByEmail(event.email) != null) {
        emit(
          const ManagementError(
            message: 'Email sudah terdaftar pada pengguna lain.',
          ),
        );
        return;
      }

      String passwordHash = user.passwordHash;
      if (event.password != null && event.password!.trim().isNotEmpty) {
        passwordHash = BCrypt.hashpw(event.password!, BCrypt.gensalt());
      }

      final updated = UserModel(
        id: user.id,
        name: event.name,
        email: event.email,
        passwordHash: passwordHash,
        role: event.role,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      )..deviceId = user.deviceId;

      await _userDatasource.saveUser(updated);
      emit(const ManagementSuccess(message: 'Pengguna berhasil diperbarui.'));
    } catch (e) {
      emit(
        ManagementError(message: 'Gagal memperbarui pengguna: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateSite(
    UpdateSite event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final site = _siteDatasource.getSiteById(event.siteId);
      if (site == null) {
        emit(const ManagementError(message: 'Lokasi tidak ditemukan.'));
        return;
      }

      final updated = SiteModel(
        id: site.id,
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
      );

      await _siteDatasource.saveSite(updated);
      emit(const ManagementSuccess(message: 'Lokasi berhasil diperbarui.'));
    } catch (e) {
      emit(
        ManagementError(message: 'Gagal memperbarui lokasi: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateShift(
    UpdateShift event,
    Emitter<ManagementState> emit,
  ) async {
    emit(const ManagementLoading());
    try {
      final shift = _shiftDatasource.getShiftById(event.shiftId);
      if (shift == null) {
        emit(const ManagementError(message: 'Shift tidak ditemukan.'));
        return;
      }

      final updated = ShiftModel(
        id: shift.id,
        name: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
      );

      await _shiftDatasource.saveShift(updated);
      emit(const ManagementSuccess(message: 'Shift berhasil diperbarui.'));
    } catch (e) {
      emit(
        ManagementError(message: 'Gagal memperbarui shift: ${e.toString()}'),
      );
    }
  }
}
