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
  })  : _userDatasource = userDatasource,
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
      emit(ManagementError(message: 'Gagal memuat daftar pengguna: ${e.toString()}'));
    }
  }

  Future<void> _onCreateUser(
      CreateUser event, Emitter<ManagementState> emit) async {
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
      DeleteUser event, Emitter<ManagementState> emit) async {
    await _userDatasource.deleteUser(event.userId);
    emit(const ManagementSuccess(message: 'Pengguna dihapus.'));
  }

  Future<void> _onUnbindDevice(
      UnbindDevice event, Emitter<ManagementState> emit) async {
    await _userDatasource.updateDeviceId(event.userId, null);
    emit(const ManagementSuccess(message: 'Tautan perangkat berhasil dilepas.'));
  }

  void _onLoadSites(LoadSites event, Emitter<ManagementState> emit) {
    emit(const ManagementLoading());
    try {
      final sites = _siteDatasource.getAllSites();
      emit(SitesLoaded(sites: sites));
    } catch (e) {
      emit(ManagementError(message: 'Gagal memuat daftar lokasi kerja: ${e.toString()}'));
    }
  }

  Future<void> _onCreateSite(
      CreateSite event, Emitter<ManagementState> emit) async {
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
      DeleteSite event, Emitter<ManagementState> emit) async {
    await _siteDatasource.deleteSite(event.siteId);
    emit(const ManagementSuccess(message: 'Site dihapus.'));
  }

  void _onLoadShifts(LoadShifts event, Emitter<ManagementState> emit) {
    emit(const ManagementLoading());
    try {
      final shifts = _shiftDatasource.getAllShifts();
      emit(ShiftsLoaded(shifts: shifts));
    } catch (e) {
      emit(ManagementError(message: 'Gagal memuat daftar shift: ${e.toString()}'));
    }
  }

  Future<void> _onCreateShift(
      CreateShift event, Emitter<ManagementState> emit) async {
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
      DeleteShift event, Emitter<ManagementState> emit) async {
    await _shiftDatasource.deleteShift(event.shiftId);
    emit(const ManagementSuccess(message: 'Shift dihapus.'));
  }

  Future<void> _onAssignShift(
      AssignShift event, Emitter<ManagementState> emit) async {
    emit(const ManagementLoading());
    try {
      final existing = _assignmentDatasource.getAssignmentForUserOnDate(
          event.userId, event.date);
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
      emit(ManagementError(
          message: 'Gagal assign shift: ${e.toString()}'));
    }
  }

  void _onLoadAssignments(
      LoadShiftAssignments event, Emitter<ManagementState> emit) {
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
      emit(ManagementError(message: 'Gagal memuat daftar penugasan: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAssignment(
      DeleteAssignment event, Emitter<ManagementState> emit) async {
    emit(const ManagementLoading());
    try {
      await _assignmentDatasource.deleteAssignment(event.assignmentId);
      emit(const ManagementSuccess(message: 'Penugasan jadwal berhasil dihapus.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal menghapus penugasan: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAssignment(
      UpdateAssignment event, Emitter<ManagementState> emit) async {
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
      emit(const ManagementSuccess(message: 'Penugasan jadwal berhasil diperbarui.'));
    } catch (e) {
      emit(ManagementError(message: 'Gagal memperbarui penugasan: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateUser(
      UpdateUser event, Emitter<ManagementState> emit) async {
    emit(const ManagementLoading());
    try {
      final user = _userDatasource.getUserById(event.userId);
      if (user == null) {
        emit(const ManagementError(message: 'Pengguna tidak ditemukan.'));
        return;
      }

      if (user.email != event.email &&
          _userDatasource.getUserByEmail(event.email) != null) {
        emit(const ManagementError(message: 'Email sudah terdaftar pada pengguna lain.'));
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
      emit(ManagementError(message: 'Gagal memperbarui pengguna: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSite(
      UpdateSite event, Emitter<ManagementState> emit) async {
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
      emit(ManagementError(message: 'Gagal memperbarui lokasi: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateShift(
      UpdateShift event, Emitter<ManagementState> emit) async {
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
      emit(ManagementError(message: 'Gagal memperbarui shift: ${e.toString()}'));
    }
  }
}
