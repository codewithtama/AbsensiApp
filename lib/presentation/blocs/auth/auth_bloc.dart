import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/models/user_model.dart';
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
      // Seed superuser on first launch
      await _seedDefaultSuperuser();

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

      // Device binding check
      final deviceId = await _getDeviceId();
      if (user.deviceId == null) {
        // First login — bind to this device
        user.deviceId = deviceId;
        await user.save();
      } else if (user.deviceId != deviceId) {
        emit(const AuthError(
          message: 'Perangkat tidak sesuai. Hubungi Superuser untuk unbind.',
        ));
        return;
      }

      // Save session
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
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }

  Future<void> _seedDefaultSuperuser() async {
    final settingsBox = Hive.box(HiveBoxes.appSettings);
    final isSeeded = settingsBox.get(AppSettingsKeys.isSeeded) as bool?;

    if (isSeeded == true) return;
    if (!_userDatasource.isEmpty) return;

    final hashedPassword = BCrypt.hashpw('admin123', BCrypt.gensalt());
    final superuser = UserModel(
      id: const Uuid().v4(),
      name: 'Superuser',
      email: 'admin@absensi.app',
      passwordHash: hashedPassword,
      role: UserRole.superuser,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userDatasource.saveUser(superuser);
    await settingsBox.put(AppSettingsKeys.isSeeded, true);
  }
}
