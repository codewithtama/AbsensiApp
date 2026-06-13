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
import 'package:absensi_app/core/utils/date_formatters.dart';
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

      // Step 1: Cek apakah ada sesi clock-in aktif yang belum di-clock-out
      if (_attendanceDatasource.hasActiveClockIn(_currentUserId)) {
        emit(const AttendanceError(
          message: 'Anda masih memiliki sesi absen masuk yang aktif. Lakukan absen keluar terlebih dahulu.',
          errorType: 'already_clocked_in',
        ));
        return;
      }

      // Step 1b: Cek apakah siklus shift terakhir sudah selesai (clock-in + clock-out dalam 24 jam)
      if (_attendanceDatasource.hasCompletedShiftRecently(_currentUserId)) {
        emit(const AttendanceError(
          message: 'Siklus absen shift Anda sudah selesai. Tunggu jadwal shift berikutnya untuk absen kembali.',
          errorType: 'attendance_complete',
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
      
      // Cari jadwal untuk HARI INI
      var assignment = assignmentDatasource.getAssignmentForUserOnDate(_currentUserId, currentTime);
      var shift = assignment != null ? shiftDatasource.getShiftById(assignment.shiftId) : null;

      // Jika tidak ada jadwal hari ini, cek apakah ada jadwal kemarin yang merupakan overnight shift dan masih berjalan.
      if (shift == null) {
        final yesterday = currentTime.subtract(const Duration(days: 1));
        final yesterdayAssignment = assignmentDatasource.getAssignmentForUserOnDate(_currentUserId, yesterday);
        if (yesterdayAssignment != null) {
          final yesterdayShift = shiftDatasource.getShiftById(yesterdayAssignment.shiftId);
          if (yesterdayShift != null) {
            final startParts = yesterdayShift.startTime.split(':');
            final startHour = int.parse(startParts[0]);
            final startMinute = int.parse(startParts[1]);

            final endParts = yesterdayShift.endTime.split(':');
            final endHour = int.parse(endParts[0]);
            final endMinute = int.parse(endParts[1]);

            final shiftStart = DateTime(yesterday.year, yesterday.month, yesterday.day, startHour, startMinute);
            var shiftEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, endHour, endMinute);

            if (shiftEnd.isBefore(shiftStart)) {
              shiftEnd = shiftEnd.add(const Duration(days: 1));
              if (currentTime.isBefore(shiftEnd)) {
                assignment = yesterdayAssignment;
                shift = yesterdayShift;
              }
            }
          }
        }
      }

      if (shift == null) {
        emit(const AttendanceError(
          message: 'Anda tidak memiliki jadwal shift aktif saat ini. Silakan hubungi admin.',
          errorType: 'no_shift_assigned',
        ));
        return;
      }

      bool? isLate;
      int? delayMinutes;

      final startParts = shift.startTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);

      final endParts = shift.endTime.split(':');
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Tentukan tanggal mulai shift berdasarkan kapan user absen masuk
      var shiftStart = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        startHour,
        startMinute,
      );
      var shiftEnd = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        endHour,
        endMinute,
      );

      // Jika kita mencocokkan shift kemarin yang berjalan melewati midnight
      if (assignment != null && !DateFormatters.isSameDay(assignment.date, currentTime)) {
        final assignDate = assignment.date.toLocal();
        shiftStart = DateTime(
          assignDate.year,
          assignDate.month,
          assignDate.day,
          startHour,
          startMinute,
        );
        shiftEnd = DateTime(
          assignDate.year,
          assignDate.month,
          assignDate.day,
          endHour,
          endMinute,
        );
      }

      if (shiftEnd.isBefore(shiftStart)) {
        shiftEnd = shiftEnd.add(const Duration(days: 1));
      }

      // 1. Batasi absen terlalu cepat (maksimal 2 jam sebelum shift)
      final earliestClockIn = shiftStart.subtract(const Duration(hours: 2));
      if (currentTime.isBefore(earliestClockIn)) {
        emit(AttendanceError(
          message: 'Absen masuk belum dibuka. Shift "${shift.name}" baru dimulai pukul ${shift.startTime}. Anda dapat absen mulai pukul ${DateFormatters.formatTime(earliestClockIn)}.',
          errorType: 'too_early_clock_in',
        ));
        return;
      }

      // 2. Batasi absen jika shift sudah berakhir
      if (currentTime.isAfter(shiftEnd)) {
        emit(AttendanceError(
          message: 'Shift "${shift.name}" Anda telah berakhir pada pukul ${shift.endTime}. Anda tidak dapat melakukan absen masuk.',
          errorType: 'shift_already_ended',
        ));
        return;
      }

      final diff = currentTime.difference(shiftStart).inMinutes;
      // Batas toleransi keterlambatan: 15 menit
      isLate = diff > 15;
      delayMinutes = diff;

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
        shiftId: shift.id,
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
      final shiftDatasource = sl<ShiftLocalDatasource>();
      final shift = clockIn.shiftId != null ? shiftDatasource.getShiftById(clockIn.shiftId!) : null;

      bool? isEarlyOut;
      int? delayMinutes;

      if (shift != null) {
        final startParts = shift.startTime.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);

        final endParts = shift.endTime.split(':');
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        final clockInLocal = clockIn.timestamp.toLocal();
        final shiftStart = DateTime(
          clockInLocal.year,
          clockInLocal.month,
          clockInLocal.day,
          startHour,
          startMinute,
        );
        var shiftEnd = DateTime(
          clockInLocal.year,
          clockInLocal.month,
          clockInLocal.day,
          endHour,
          endMinute,
        );

        if (shiftEnd.isBefore(shiftStart)) {
          shiftEnd = shiftEnd.add(const Duration(days: 1));
        }

        final diff = shiftEnd.difference(currentTime.toLocal()).inMinutes;
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
