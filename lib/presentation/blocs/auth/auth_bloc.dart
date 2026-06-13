import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/site_model.dart';
import 'package:absensi_app/data/models/shift_model.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_event.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_state.dart';
import 'package:uuid/uuid.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserLocalDatasource _userDatasource;

  AuthBloc({required UserLocalDatasource userDatasource})
      : _userDatasource = userDatasource,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckSession>(_onCheckSession);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _seedDefaultData();

      final user = _userDatasource.getUserByEmail(event.email);
      if (user == null) {
        emit(const AuthError(message: 'Email atau password salah.'));
        return;
      }

      final passwordValid = BCrypt.checkpw(event.password, user.passwordHash);
      if (!passwordValid) {
        emit(const AuthError(message: 'Email atau password salah.'));
        return;
      }

      final deviceId = await _getDeviceId();
      final isDemoUser = [
        'admin@absensi.app',
        'manager@absensi.app',
        'supervisor@absensi.app',
        'leader@absensi.app',
        'karyawan@absensi.app'
      ].contains(user.email.toLowerCase());

      if (isDemoUser) {
        // Automatically sync device ID for demo users to avoid locking out developers/testers
        user.deviceId = deviceId;
        await user.save();
      } else {
        if (user.deviceId == null) {
          user.deviceId = deviceId;
          await user.save();
        } else if (user.deviceId != deviceId) {
          emit(const AuthError(
            message: 'Perangkat tidak sesuai. Hubungi Superuser untuk melepas tautan perangkat.',
          ));
          return;
        }
      }

      final settingsBox = Hive.box(HiveBoxes.appSettings);
      await settingsBox.put(AppSettingsKeys.currentUserId, user.id);

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Login gagal: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final settingsBox = Hive.box(HiveBoxes.appSettings);
    await settingsBox.delete(AppSettingsKeys.currentUserId);
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckSession(
    CheckSession event,
    Emitter<AuthState> emit,
  ) async {
    final settingsBox = Hive.box(HiveBoxes.appSettings);
    final userId = settingsBox.get(AppSettingsKeys.currentUserId) as String?;

    if (userId == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    final user = _userDatasource.getUserById(userId);
    if (user == null) {
      await settingsBox.delete(AppSettingsKeys.currentUserId);
      emit(const AuthUnauthenticated());
      return;
    }

    emit(AuthAuthenticated(user: user));
  }

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'web-fallback-device-id';
      }
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios-fallback-device-id';
      }
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      }
      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'macos-fallback-device-id';
      }
      return 'generic-offline-device-id';
    } catch (_) {
      return 'fallback-error-device-id';
    }
  }

  Future<void> _seedDefaultData() async {
    final salt = BCrypt.gensalt();
    final usersBox = Hive.box<UserModel>(HiveBoxes.users);
    final sitesBox = Hive.box<SiteModel>(HiveBoxes.sites);
    final shiftsBox = Hive.box<ShiftModel>(HiveBoxes.shifts);
    final assignmentsBox = Hive.box<ShiftAssignmentModel>(HiveBoxes.shiftAssignments);

    // 1. Seed Sites if empty
    if (sitesBox.isEmpty) {
      final defaultSites = [
        SiteModel(
          id: const Uuid().v4(),
          name: 'Kantor Pusat Jakarta',
          latitude: -6.2088,
          longitude: 106.8456,
          radiusMeters: 150.0,
        ),
        SiteModel(
          id: const Uuid().v4(),
          name: 'Warehouse Bekasi',
          latitude: -6.2383,
          longitude: 106.9756,
          radiusMeters: 200.0,
        ),
      ];
      for (var site in defaultSites) {
        await sitesBox.put(site.id, site);
      }
    }

    // 2. Seed Shifts if empty
    if (shiftsBox.isEmpty) {
      final defaultShifts = [
        ShiftModel(
          id: const Uuid().v4(),
          name: 'Shift Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
        ShiftModel(
          id: const Uuid().v4(),
          name: 'Shift Malam',
          startTime: '20:00',
          endTime: '05:00',
        ),
      ];
      for (var shift in defaultShifts) {
        await shiftsBox.put(shift.id, shift);
      }
    }

    // Retrieve seeded sites and shifts
    final sites = sitesBox.values.toList();
    final shifts = shiftsBox.values.toList();
    if (sites.isEmpty || shifts.isEmpty) return;

    final siteJkt = sites.firstWhere((s) => s.name.contains('Jakarta'), orElse: () => sites.first);
    final siteBekasi = sites.firstWhere((s) => s.name.contains('Bekasi'), orElse: () => sites.first);
    final shiftPagi = shifts.firstWhere((s) => s.name.contains('Pagi'), orElse: () => shifts.first);
    final shiftMalam = shifts.firstWhere((s) => s.name.contains('Malam'), orElse: () => shifts.last);

    // 3. Seed Users if they don't exist by email
    final defaultUsers = [
      UserModel(
        id: const Uuid().v4(),
        name: 'Superuser Admin',
        email: 'admin@absensi.app',
        passwordHash: BCrypt.hashpw('admin123', salt),
        role: UserRole.superuser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        id: const Uuid().v4(),
        name: 'Budi Manager',
        email: 'manager@absensi.app',
        passwordHash: BCrypt.hashpw('manager123', salt),
        role: UserRole.manager,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        id: const Uuid().v4(),
        name: 'Siti Supervisor',
        email: 'supervisor@absensi.app',
        passwordHash: BCrypt.hashpw('spv123', salt),
        role: UserRole.supervisor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        id: const Uuid().v4(),
        name: 'Adit Leader',
        email: 'leader@absensi.app',
        passwordHash: BCrypt.hashpw('leader123', salt),
        role: UserRole.leader,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        id: const Uuid().v4(),
        name: 'Rian Karyawan',
        email: 'karyawan@absensi.app',
        passwordHash: BCrypt.hashpw('karyawan123', salt),
        role: UserRole.karyawan,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var defaultUser in defaultUsers) {
      final existingUser = usersBox.values.cast<UserModel?>().firstWhere(
            (u) => u?.email.toLowerCase() == defaultUser.email.toLowerCase(),
            orElse: () => null,
          );

      final String userId;
      if (existingUser == null) {
        await usersBox.put(defaultUser.id, defaultUser);
        userId = defaultUser.id;
      } else {
        userId = existingUser.id;
      }

      // 4. Seed Shift Assignments for the last 7 days and next 7 days to make calendar/attendance work
      final userRole = existingUser?.role ?? defaultUser.role;
      if (userRole != UserRole.superuser) {
        final userAssignments = assignmentsBox.values.where((a) => a.userId == userId);
        if (userAssignments.isEmpty) {
          final targetSite = (userRole == UserRole.supervisor) ? siteBekasi : siteJkt;
          final targetShift = (userRole == UserRole.supervisor) ? shiftMalam : shiftPagi;

          final today = DateTime.now();
          for (int i = -7; i <= 7; i++) {
            final targetDate = today.add(Duration(days: i));
            final assignment = ShiftAssignmentModel(
              id: const Uuid().v4(),
              userId: userId,
              shiftId: targetShift.id,
              siteId: targetSite.id,
              date: targetDate,
              assignedBy: 'System Seeder',
            );
            await assignmentsBox.put(assignment.id, assignment);
          }
        }
      }
    }

    final settingsBox = Hive.box(HiveBoxes.appSettings);
    await settingsBox.put(AppSettingsKeys.isSeeded, true);
  }
}
