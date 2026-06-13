import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/utils/device_security.dart';
import 'package:absensi_app/core/utils/geofence_calculator.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_event.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_state.dart';
import 'package:absensi_app/injection.dart';

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

  /// Memeriksa apakah waktu perangkat dimanipulasi (dimundurkan) oleh pengguna.
  bool _isClockTampered(DateTime currentTime) {
    final allAttendance = _attendanceDatasource.getAllAttendance();
    if (allAttendance.isEmpty) return false;

    // Ambil waktu absensi paling terakhir yang pernah tercatat di database lokal
    final latestTimestamp = allAttendance
        .map((a) => a.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // Jika waktu saat ini lebih lampau dibanding catatan terakhir, terindikasi fraud jam
    return currentTime.isBefore(latestTimestamp);
  }

  Future<void> _onClockIn(
    ClockInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final currentTime = DateTime.now();
      if (_isClockTampered(currentTime)) {
        emit(const AttendanceError(
          message: 'Manipulasi waktu terdeteksi. Jam perangkat Anda tidak valid.',
          errorType: 'time_tampering_detected',
        ));
        return;
      }

      // Step 1: Check if already clocked in
      if (_attendanceDatasource.hasClockInToday(_currentUserId)) {
        emit(const AttendanceError(
          message: 'Anda sudah melakukan absen masuk hari ini.',
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
            : 'Lokasi palsu terdeteksi.';
        emit(AttendanceError(message: msg, errorType: securityResult));
        return;
      }

      // Step 3: Get current location
      emit(const AttendanceLoading(stepMessage: 'Mendapatkan lokasi...'));
      final position = await _getCurrentPosition();
      if (position == null) {
        emit(const AttendanceError(
          message: 'Gagal mendapatkan lokasi. Pastikan GPS aktif.',
          errorType: 'location_error',
        ));
        return;
      }

      // Step 4: Geofence check
      emit(const AttendanceLoading(stepMessage: 'Memeriksa area geofence...'));
      final site = _siteDatasource.getSiteById(event.siteId);
      if (site == null) {
        emit(const AttendanceError(
          message: 'Lokasi kerja tidak ditemukan.',
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

      // Get shift and calculate lateness
      final assignmentDatasource = sl<ShiftAssignmentLocalDatasource>();
      final shiftDatasource = sl<ShiftLocalDatasource>();
      final assignment = assignmentDatasource.getAssignmentForUserOnDate(_currentUserId, currentTime);
      final shift = assignment != null ? shiftDatasource.getShiftById(assignment.shiftId) : null;

      bool? isLate;
      int? delayMinutes;

      if (shift != null) {
        final parts = shift.startTime.split(':');
        final shiftHour = int.parse(parts[0]);
        final shiftMinute = int.parse(parts[1]);
        final shiftDateTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          shiftHour,
          shiftMinute,
        );
        
        final diff = currentTime.difference(shiftDateTime).inMinutes;
        // Batas toleransi keterlambatan: 15 menit
        isLate = diff > 15;
        delayMinutes = diff;
      }

      // Get device info
      String deviceName = 'Tidak Diketahui';
      String deviceOs = 'Tidak Diketahui';
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (kIsWeb) {
          final webInfo = await deviceInfo.webBrowserInfo;
          deviceName = webInfo.browserName.name;
          deviceOs = 'Web';
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
          deviceOs = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
          deviceOs = 'iOS ${iosInfo.systemVersion}';
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          deviceName = windowsInfo.computerName;
          deviceOs = 'Windows';
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          deviceName = macInfo.model;
          deviceOs = 'macOS';
        }
      } catch (_) {}

      // Get network connection type
      String networkType = 'Offline';
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          networkType = 'WiFi';
        } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
          networkType = 'Seluler';
        } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
          networkType = 'Ethernet';
        } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
          networkType = 'VPN';
        } else if (connectivityResult.contains(ConnectivityResult.none)) {
          networkType = 'Offline';
        }
      } catch (_) {}

      // Step 6: Save attendance
      emit(const AttendanceLoading(stepMessage: 'Menyimpan data absensi...'));
      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        siteId: event.siteId,
        shiftId: shift?.id,
        status: AttendanceStatus.clockIn,
        timestamp: currentTime,
        latitude: position.latitude,
        longitude: position.longitude,
        deviceName: deviceName,
        deviceOs: deviceOs,
        networkType: networkType,
        isLate: isLate,
        isEarlyOut: false,
        delayMinutes: delayMinutes,
      );

      await _attendanceDatasource.saveAttendance(attendance);
      emit(ClockInSuccess(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: 'Absen masuk gagal: ${e.toString()}'));
    }
  }

  Future<void> _onClockOut(
    ClockOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final currentTime = DateTime.now();
      if (_isClockTampered(currentTime)) {
        emit(const AttendanceError(
          message: 'Manipulasi waktu terdeteksi. Jam perangkat Anda tidak valid.',
          errorType: 'time_tampering_detected',
        ));
        return;
      }

      // Check if clocked in
      final clockIn = _attendanceDatasource.getTodayClockIn(_currentUserId);
      if (clockIn == null) {
        emit(const AttendanceError(
          message: 'Anda belum melakukan absen masuk hari ini.',
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
            : 'Lokasi palsu terdeteksi.';
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
        emit(const AttendanceError(message: 'Lokasi kerja tidak ditemukan.'));
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

      // Get shift and calculate early clock-out
      final assignmentDatasource = sl<ShiftAssignmentLocalDatasource>();
      final shiftDatasource = sl<ShiftLocalDatasource>();
      final assignment = assignmentDatasource.getAssignmentForUserOnDate(_currentUserId, currentTime);
      final shift = assignment != null ? shiftDatasource.getShiftById(assignment.shiftId) : null;

      bool? isEarlyOut;
      int? delayMinutes;

      if (shift != null) {
        final parts = shift.endTime.split(':');
        final shiftHour = int.parse(parts[0]);
        final shiftMinute = int.parse(parts[1]);
        final shiftDateTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          shiftHour,
          shiftMinute,
        );
        
        final diff = shiftDateTime.difference(currentTime).inMinutes;
        // Toleransi pulang cepat: 15 menit
        isEarlyOut = diff > 15;
        delayMinutes = diff;
      }

      // Get device info
      String deviceName = 'Tidak Diketahui';
      String deviceOs = 'Tidak Diketahui';
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (kIsWeb) {
          final webInfo = await deviceInfo.webBrowserInfo;
          deviceName = webInfo.browserName.name;
          deviceOs = 'Web';
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
          deviceOs = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
          deviceOs = 'iOS ${iosInfo.systemVersion}';
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          deviceName = windowsInfo.computerName;
          deviceOs = 'Windows';
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          deviceName = macInfo.model;
          deviceOs = 'macOS';
        }
      } catch (_) {}

      // Get network connection type
      String networkType = 'Offline';
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          networkType = 'WiFi';
        } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
          networkType = 'Seluler';
        } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
          networkType = 'Ethernet';
        } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
          networkType = 'VPN';
        } else if (connectivityResult.contains(ConnectivityResult.none)) {
          networkType = 'Offline';
        }
      } catch (_) {}

      // Save
      emit(const AttendanceLoading(stepMessage: 'Menyimpan data absensi...'));
      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: _currentUserId,
        siteId: event.siteId,
        shiftId: shift?.id,
        status: AttendanceStatus.clockOut,
        timestamp: currentTime,
        latitude: position.latitude,
        longitude: position.longitude,
        deviceName: deviceName,
        deviceOs: deviceOs,
        networkType: networkType,
        isLate: false,
        isEarlyOut: isEarlyOut,
        delayMinutes: delayMinutes,
      );

      await _attendanceDatasource.saveAttendance(attendance);

      final workDuration =
          attendance.timestamp.difference(clockIn.timestamp);

      emit(ClockOutSuccess(
        attendance: attendance,
        workDuration: workDuration,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Absen keluar gagal: ${e.toString()}'));
    }
  }

  Future<void> _onLoadHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final records = _attendanceDatasource.getAttendanceByUser(event.userId);
      emit(AttendanceHistoryLoaded(records: records));
    } catch (e) {
      emit(AttendanceError(message: 'Gagal memuat riwayat absensi Anda: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTeamAttendance(
    LoadTeamAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final date = event.date ?? DateTime.now();
      final records = _attendanceDatasource.getAttendanceByDateRange(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59),
      );
      emit(AttendanceHistoryLoaded(records: records));
    } catch (e) {
      emit(AttendanceError(message: 'Gagal memuat data absensi tim: ${e.toString()}'));
    }
  }

  Future<void> _onCheckTodayStatus(
    CheckTodayStatus event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final clockIn = _attendanceDatasource.getTodayClockIn(event.userId);
      emit(AttendanceStatusChecked(
        isClockedIn: clockIn != null,
        todayClockIn: clockIn,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Gagal memeriksa status absensi hari ini: ${e.toString()}'));
    }
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
