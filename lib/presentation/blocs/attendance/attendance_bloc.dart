import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/utils/device_security.dart';
import 'package:absensi_app/core/utils/geofence_calculator.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_event.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceLocalDatasource _attendanceDatasource;
  final SiteLocalDatasource _siteDatasource;
  final DeviceSecurity _deviceSecurity;
  final GeofenceCalculator _geofenceCalculator;
  final LocalAuthentication _localAuth;
  final String _currentUserId;

  AttendanceBloc({
    required AttendanceLocalDatasource attendanceDatasource,
    required SiteLocalDatasource siteDatasource,
    required DeviceSecurity deviceSecurity,
    required GeofenceCalculator geofenceCalculator,
    required LocalAuthentication localAuth,
    required String currentUserId,
  })  : _attendanceDatasource = attendanceDatasource,
        _siteDatasource = siteDatasource,
        _deviceSecurity = deviceSecurity,
        _geofenceCalculator = geofenceCalculator,
        _localAuth = localAuth,
        _currentUserId = currentUserId,
        super(const AttendanceInitial()) {
    on<ClockInRequested>(_onClockIn);
    on<ClockOutRequested>(_onClockOut);
    on<LoadAttendanceHistory>(_onLoadHistory);
    on<LoadTeamAttendance>(_onLoadTeamAttendance);
    on<CheckTodayStatus>(_onCheckTodayStatus);
  }

  Future<void> _onClockIn(
    ClockInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Step 1: Check if already clocked in
      if (_attendanceDatasource.hasClockInToday(_currentUserId)) {
        emit(const AttendanceError(
          message: 'Anda sudah melakukan Clock In hari ini.',
          errorType: 'already_clocked_in',
        ));
        return;
      }

      // Step 2: Device security check
      emit(const AttendanceLoading(stepMessage: 'Memeriksa keamanan perangkat...'));
      final securityResult = await _deviceSecurity.runSecurityChecks();
      if (securityResult != null) {
        final msg = securityResult == 'rooted'
            ? 'Perangkat terdeteksi di-root.'
            : 'Lokasi palsu (Mock GPS) terdeteksi.';
        emit(AttendanceError(message: msg, errorType: securityResult));
        return;
      }

      // Step 3: Get current location
      emit(const AttendanceLoading(stepMessage: 'Mendapatkan lokasi...'));
      final position = await _getCurrentPosition();
      if (position == null) {
        emit(const AttendanceError(
          message: 'Tidak dapat mendapatkan lokasi. Pastikan GPS aktif.',
          errorType: 'location_error',
        ));
        return;
      }

      // Step 4: Geofence check
      emit(const AttendanceLoading(stepMessage: 'Memeriksa area geofence...'));
      final site = _siteDatasource.getSiteById(event.siteId);
      if (site == null) {
        emit(const AttendanceError(
          message: 'Site tidak ditemukan.',
          errorType: 'site_not_found',
        ));
        return;
      }

      final geoResult = _geofenceCalculator.checkGeofence(
        userLat: position.latitude,
        userLng: position.longitude,
        siteLat: site.latitude,
        siteLng: site.longitude,
        radiusMeters: site.radiusMeters,
      );

      if (!geoResult.isWithin) {
        emit(AttendanceError(
          message:
              'Anda di luar area absensi. Jarak: ${geoResult.distance.toStringAsFixed(0)}m, Batas: ${site.radiusMeters.toStringAsFixed(0)}m',
          errorType: 'out_of_geofence',
        ));
        return;
      }

      // Step 5: Biometric authentication
      emit(const AttendanceLoading(stepMessage: 'Autentikasi biometrik...'));
      final authenticated = await _authenticateBiometric();
      if (!authenticated) {
        emit(const AttendanceError(
          message: 'Autentikasi biometrik gagal.',
          errorType: 'biometric_failed',
        ));
        return;
      }

      // Step 6: Save attendance
      emit(const AttendanceLoading(stepMessage: 'Menyimpan data absensi...'));
      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        siteId: event.siteId,
        status: AttendanceStatus.clockIn,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _attendanceDatasource.saveAttendance(attendance);
      emit(ClockInSuccess(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: 'Clock In gagal: ${e.toString()}'));
    }
  }

  Future<void> _onClockOut(
    ClockOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Check if clocked in
      final clockIn = _attendanceDatasource.getTodayClockIn(_currentUserId);
      if (clockIn == null) {
        emit(const AttendanceError(
          message: 'Anda belum melakukan Clock In hari ini.',
          errorType: 'not_clocked_in',
        ));
        return;
      }

      // Device security
      emit(const AttendanceLoading(stepMessage: 'Memeriksa keamanan perangkat...'));
      final securityResult = await _deviceSecurity.runSecurityChecks();
      if (securityResult != null) {
        final msg = securityResult == 'rooted'
            ? 'Perangkat terdeteksi di-root.'
            : 'Lokasi palsu (Mock GPS) terdeteksi.';
        emit(AttendanceError(message: msg, errorType: securityResult));
        return;
      }

      // Location
      emit(const AttendanceLoading(stepMessage: 'Mendapatkan lokasi...'));
      final position = await _getCurrentPosition();
      if (position == null) {
        emit(const AttendanceError(
          message: 'Tidak dapat mendapatkan lokasi.',
          errorType: 'location_error',
        ));
        return;
      }

      // Geofence
      emit(const AttendanceLoading(stepMessage: 'Memeriksa area geofence...'));
      final site = _siteDatasource.getSiteById(event.siteId);
      if (site == null) {
        emit(const AttendanceError(message: 'Site tidak ditemukan.'));
        return;
      }

      final geoResult = _geofenceCalculator.checkGeofence(
        userLat: position.latitude,
        userLng: position.longitude,
        siteLat: site.latitude,
        siteLng: site.longitude,
        radiusMeters: site.radiusMeters,
      );

      if (!geoResult.isWithin) {
        emit(AttendanceError(
          message:
              'Anda di luar area absensi. Jarak: ${geoResult.distance.toStringAsFixed(0)}m',
          errorType: 'out_of_geofence',
        ));
        return;
      }

      // Biometric
      emit(const AttendanceLoading(stepMessage: 'Autentikasi biometrik...'));
      final authenticated = await _authenticateBiometric();
      if (!authenticated) {
        emit(const AttendanceError(
          message: 'Autentikasi biometrik gagal.',
          errorType: 'biometric_failed',
        ));
        return;
      }

      // Save
      emit(const AttendanceLoading(stepMessage: 'Menyimpan data absensi...'));
      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        siteId: event.siteId,
        status: AttendanceStatus.clockOut,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _attendanceDatasource.saveAttendance(attendance);

      final workDuration =
          attendance.timestamp.difference(clockIn.timestamp);

      emit(ClockOutSuccess(
        attendance: attendance,
        workDuration: workDuration,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Clock Out gagal: ${e.toString()}'));
    }
  }

  Future<void> _onLoadHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    final records = _attendanceDatasource.getAttendanceByUser(event.userId);
    emit(AttendanceHistoryLoaded(records: records));
  }

  Future<void> _onLoadTeamAttendance(
    LoadTeamAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    final date = event.date ?? DateTime.now();
    final records = _attendanceDatasource.getAttendanceByDateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
    emit(AttendanceHistoryLoaded(records: records));
  }

  Future<void> _onCheckTodayStatus(
    CheckTodayStatus event,
    Emitter<AttendanceState> emit,
  ) async {
    final clockIn = _attendanceDatasource.getTodayClockIn(event.userId);
    emit(AttendanceStatusChecked(
      isClockedIn: clockIn != null,
      todayClockIn: clockIn,
    ));
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _authenticateBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuth && !isDeviceSupported) {
        // Fallback: allow if no biometric hardware
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk absensi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return true; // Graceful fallback
    }
  }
}
