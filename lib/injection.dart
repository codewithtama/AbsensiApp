import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:absensi_app/core/utils/device_security.dart';
import 'package:absensi_app/core/utils/geofence_calculator.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/leave_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Utilities
  sl.registerLazySingleton<DeviceSecurity>(() => const DeviceSecurity());
  sl.registerLazySingleton<GeofenceCalculator>(() => const GeofenceCalculator());
  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());

  // Datasources
  sl.registerLazySingleton<UserLocalDatasource>(() => UserLocalDatasource());
  sl.registerLazySingleton<AttendanceLocalDatasource>(
      () => AttendanceLocalDatasource());
  sl.registerLazySingleton<LeaveLocalDatasource>(() => LeaveLocalDatasource());
  sl.registerLazySingleton<SiteLocalDatasource>(() => SiteLocalDatasource());
  sl.registerLazySingleton<ShiftLocalDatasource>(() => ShiftLocalDatasource());
  sl.registerLazySingleton<ShiftAssignmentLocalDatasource>(
      () => ShiftAssignmentLocalDatasource());
}
